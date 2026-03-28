#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/syscall.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <android/log.h>

// PTY support on Android (Bionic libc provides openpty in <pty.h>)
#include <pty.h>

#define TAG "ZrokExecNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// memfd_create syscall wrapper (available on kernel >= 3.17, Android 10+)
static int my_memfd_create(const char *name, unsigned int flags) {
    return (int)syscall(__NR_memfd_create, name, flags);
}

// Struct to track child process PTY
typedef struct {
    pid_t pid;
    int master_fd;   // PTY master — used for both reading and writing
    int stderr_fd;   // Separate stderr pipe (PTY only covers stdout/stdin)
} ChildProcess;

// Global array of child processes (max 16 concurrent)
#define MAX_CHILDREN 16
static ChildProcess children[MAX_CHILDREN];
static int children_count = 0;

static int find_child(pid_t pid) {
    for (int i = 0; i < children_count; i++) {
        if (children[i].pid == pid) return i;
    }
    return -1;
}

/*
 * Strip ANSI escape sequences from a buffer in-place.
 * Handles: CSI sequences (\033[...X), OSC sequences (\033]...\007),
 * and simple two-byte escapes (\033X).
 * Returns the new length of the stripped string.
 */
static int strip_ansi(char *buf, int len) {
    int r = 0, w = 0;
    while (r < len) {
        if (buf[r] == '\033') {
            r++;
            if (r < len && buf[r] == '[') {
                // CSI sequence: skip until a letter (0x40-0x7E)
                r++;
                while (r < len && !((buf[r] >= 0x40 && buf[r] <= 0x7E))) r++;
                if (r < len) r++; // skip the final byte
            } else if (r < len && buf[r] == ']') {
                // OSC sequence: skip until BEL (\007) or ST (\033\\)
                r++;
                while (r < len) {
                    if (buf[r] == '\007') { r++; break; }
                    if (buf[r] == '\033' && r + 1 < len && buf[r+1] == '\\') { r += 2; break; }
                    r++;
                }
            } else if (r < len) {
                r++; // Simple two-byte escape
            }
        } else if (buf[r] == '\r') {
            // Skip carriage return (PTY sends \r\n, we only want \n)
            r++;
        } else {
            buf[w++] = buf[r++];
        }
    }
    buf[w] = '\0';
    return w;
}

/*
 * Load a binary from disk into a memfd file descriptor.
 * Returns the memfd fd on success, -1 on failure.
 */
static int load_binary_to_memfd(const char *path) {
    int src_fd = open(path, O_RDONLY);
    if (src_fd < 0) {
        LOGE("Cannot open binary: %s (errno=%d: %s)", path, errno, strerror(errno));
        return -1;
    }

    int mem_fd = my_memfd_create("zrok_exec", 0);
    if (mem_fd < 0) {
        LOGE("memfd_create failed (errno=%d: %s)", errno, strerror(errno));
        close(src_fd);
        return -1;
    }

    // Copy file content to memfd
    char buf[65536];
    ssize_t n;
    size_t total = 0;
    while ((n = read(src_fd, buf, sizeof(buf))) > 0) {
        ssize_t written = 0;
        while (written < n) {
            ssize_t w = write(mem_fd, buf + written, n - written);
            if (w < 0) {
                LOGE("write to memfd failed (errno=%d: %s)", errno, strerror(errno));
                close(src_fd);
                close(mem_fd);
                return -1;
            }
            written += w;
        }
        total += n;
    }
    close(src_fd);

    LOGD("Loaded %zu bytes from %s into memfd (fd=%d)", total, path, mem_fd);
    lseek(mem_fd, 0, SEEK_SET);

    return mem_fd;
}

/*
 * Fork and execute a binary directly with a PTY.
 * For binaries that already have exec permissions (e.g. bundled in APK native lib dir).
 * The PTY provides a real /dev/tty for the child process.
 *
 * Returns child PID on success, -1 on failure.
 */
JNIEXPORT jint JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeExecPty(
    JNIEnv *env, jclass clazz,
    jstring jBinaryPath,
    jobjectArray jArgs,
    jobjectArray jEnvVars,
    jstring jWorkDir
) {
    const char *binary_path = (*env)->GetStringUTFChars(env, jBinaryPath, NULL);
    if (!binary_path) {
        LOGE("Failed to get binary path string");
        return -1;
    }

    LOGD("PTY direct exec: %s", binary_path);

    // Build argv
    int argc = jArgs ? (*env)->GetArrayLength(env, jArgs) : 0;
    char **argv = (char **)calloc(argc + 2, sizeof(char *));
    argv[0] = strdup(binary_path);
    for (int i = 0; i < argc; i++) {
        jstring jarg = (jstring)(*env)->GetObjectArrayElement(env, jArgs, i);
        const char *arg = (*env)->GetStringUTFChars(env, jarg, NULL);
        argv[i + 1] = strdup(arg);
        (*env)->ReleaseStringUTFChars(env, jarg, arg);
        (*env)->DeleteLocalRef(env, jarg);
    }
    argv[argc + 1] = NULL;

    // Build envp
    int envc = jEnvVars ? (*env)->GetArrayLength(env, jEnvVars) : 0;
    char **envp = NULL;
    if (envc > 0) {
        envp = (char **)calloc(envc + 1, sizeof(char *));
        for (int i = 0; i < envc; i++) {
            jstring jenv = (jstring)(*env)->GetObjectArrayElement(env, jEnvVars, i);
            const char *envvar = (*env)->GetStringUTFChars(env, jenv, NULL);
            envp[i] = strdup(envvar);
            (*env)->ReleaseStringUTFChars(env, jenv, envvar);
            (*env)->DeleteLocalRef(env, jenv);
        }
        envp[envc] = NULL;
    }

    // Get work dir
    const char *work_dir = NULL;
    if (jWorkDir) {
        work_dir = (*env)->GetStringUTFChars(env, jWorkDir, NULL);
    }

    // Create PTY pair
    int master_fd, slave_fd;
    if (openpty(&master_fd, &slave_fd, NULL, NULL, NULL) < 0) {
        LOGE("openpty() failed (errno=%d: %s)", errno, strerror(errno));
        (*env)->ReleaseStringUTFChars(env, jBinaryPath, binary_path);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    // Configure PTY - disable echo, don't convert \n to \r\n
    struct termios tios;
    tcgetattr(slave_fd, &tios);
    tios.c_lflag &= ~(ECHO | ECHONL);
    tios.c_oflag &= ~(ONLCR);
    tcsetattr(slave_fd, TCSANOW, &tios);

    // Create stderr pipe
    int stderr_pipe[2];
    if (pipe(stderr_pipe) < 0) {
        LOGE("pipe() for stderr failed (errno=%d)", errno);
        close(master_fd); close(slave_fd);
        (*env)->ReleaseStringUTFChars(env, jBinaryPath, binary_path);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        LOGE("fork() failed (errno=%d: %s)", errno, strerror(errno));
        close(master_fd); close(slave_fd);
        close(stderr_pipe[0]); close(stderr_pipe[1]);
        (*env)->ReleaseStringUTFChars(env, jBinaryPath, binary_path);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    if (pid == 0) {
        // ---- CHILD PROCESS ----
        setsid();
        ioctl(slave_fd, TIOCSCTTY, 0);
        close(master_fd);
        close(stderr_pipe[0]);

        dup2(slave_fd, STDIN_FILENO);
        dup2(slave_fd, STDOUT_FILENO);
        dup2(stderr_pipe[1], STDERR_FILENO);
        close(slave_fd);
        close(stderr_pipe[1]);

        if (work_dir) chdir(work_dir);

        if (envp) {
            execve(binary_path, argv, envp);
        } else {
            execv(binary_path, argv);
        }

        fprintf(stderr, "execve failed for %s: %s\n", binary_path, strerror(errno));
        _exit(127);
    }

    // ---- PARENT PROCESS ----
    close(slave_fd);
    close(stderr_pipe[1]);
    (*env)->ReleaseStringUTFChars(env, jBinaryPath, binary_path);

    if (children_count < MAX_CHILDREN) {
        children[children_count].pid = pid;
        children[children_count].master_fd = master_fd;
        children[children_count].stderr_fd = stderr_pipe[0];
        children_count++;
    }

    fcntl(master_fd, F_SETFL, O_NONBLOCK);
    fcntl(stderr_pipe[0], F_SETFL, O_NONBLOCK);

    LOGD("PTY direct exec succeeded: pid=%d, master_fd=%d", pid, master_fd);

    for (int i = 0; argv[i]; i++) free(argv[i]);
    free(argv);
    if (envp) { for (int i = 0; envp[i]; i++) free(envp[i]); free(envp); }
    if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);

    return (jint)pid;
}

/*
 * Fork and execute a binary from a memfd file descriptor.
 * Uses a PTY (Pseudo-Terminal) so the child process has a real /dev/tty.
 * This allows zrok TUI commands to work without --headless.
 *
 * Returns child PID on success, -1 on failure.
 */
JNIEXPORT jint JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeExecMemfd(
    JNIEnv *env, jclass clazz,
    jstring jBinaryPath,
    jobjectArray jArgs,
    jobjectArray jEnvVars,
    jstring jWorkDir
) {
    const char *binary_path = (*env)->GetStringUTFChars(env, jBinaryPath, NULL);
    if (!binary_path) {
        LOGE("Failed to get binary path string");
        return -1;
    }

    LOGD("PTY exec: loading %s", binary_path);

    // Load binary into memfd
    int mem_fd = load_binary_to_memfd(binary_path);
    (*env)->ReleaseStringUTFChars(env, jBinaryPath, binary_path);

    if (mem_fd < 0) {
        LOGE("Failed to load binary into memfd");
        return -1;
    }

    // Build the /proc/self/fd/<N> path for execution
    char fd_path[64];
    snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", mem_fd);

    // Build argv
    int argc = jArgs ? (*env)->GetArrayLength(env, jArgs) : 0;
    char **argv = (char **)calloc(argc + 2, sizeof(char *));
    argv[0] = strdup(fd_path);
    for (int i = 0; i < argc; i++) {
        jstring jarg = (jstring)(*env)->GetObjectArrayElement(env, jArgs, i);
        const char *arg = (*env)->GetStringUTFChars(env, jarg, NULL);
        argv[i + 1] = strdup(arg);
        (*env)->ReleaseStringUTFChars(env, jarg, arg);
        (*env)->DeleteLocalRef(env, jarg);
    }
    argv[argc + 1] = NULL;

    // Build envp
    int envc = jEnvVars ? (*env)->GetArrayLength(env, jEnvVars) : 0;
    char **envp = NULL;
    if (envc > 0) {
        envp = (char **)calloc(envc + 1, sizeof(char *));
        for (int i = 0; i < envc; i++) {
            jstring jenv = (jstring)(*env)->GetObjectArrayElement(env, jEnvVars, i);
            const char *envvar = (*env)->GetStringUTFChars(env, jenv, NULL);
            envp[i] = strdup(envvar);
            (*env)->ReleaseStringUTFChars(env, jenv, envvar);
            (*env)->DeleteLocalRef(env, jenv);
        }
        envp[envc] = NULL;
    }

    // Get work dir
    const char *work_dir = NULL;
    if (jWorkDir) {
        work_dir = (*env)->GetStringUTFChars(env, jWorkDir, NULL);
    }

    // Create PTY pair (master/slave) for stdout+stdin
    int master_fd, slave_fd;
    if (openpty(&master_fd, &slave_fd, NULL, NULL, NULL) < 0) {
        LOGE("openpty() failed (errno=%d: %s), falling back to pipes", errno, strerror(errno));
        // Fallback: use regular pipes if PTY is unavailable
        close(mem_fd);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    // Configure PTY terminal settings for raw mode (no local echo, no line buffering)
    struct termios tios;
    tcgetattr(slave_fd, &tios);
    tios.c_lflag &= ~(ECHO | ECHONL); // Disable echo so we don't get duplicated input back
    tios.c_oflag &= ~(ONLCR);          // Don't convert \n to \r\n in output
    tcsetattr(slave_fd, TCSANOW, &tios);

    // Create stderr pipe (stderr is NOT part of the PTY, kept separate)
    int stderr_pipe[2];
    if (pipe(stderr_pipe) < 0) {
        LOGE("pipe() for stderr failed (errno=%d)", errno);
        close(master_fd);
        close(slave_fd);
        close(mem_fd);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    // Fork
    pid_t pid = fork();
    if (pid < 0) {
        LOGE("fork() failed (errno=%d: %s)", errno, strerror(errno));
        close(master_fd);
        close(slave_fd);
        close(mem_fd);
        close(stderr_pipe[0]); close(stderr_pipe[1]);
        free(argv);
        if (envp) free(envp);
        if (work_dir) (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
        return -1;
    }

    if (pid == 0) {
        // ---- CHILD PROCESS ----

        // Create a new session so the child becomes session leader
        // This is required for the PTY slave to become the controlling terminal
        setsid();

        // Set the PTY slave as the controlling terminal
        ioctl(slave_fd, TIOCSCTTY, 0);

        // Close master side (only parent uses it)
        close(master_fd);
        close(stderr_pipe[0]); // close read end of stderr

        // Redirect stdin and stdout to PTY slave
        dup2(slave_fd, STDIN_FILENO);
        dup2(slave_fd, STDOUT_FILENO);
        // Redirect stderr to the separate pipe
        dup2(stderr_pipe[1], STDERR_FILENO);

        close(slave_fd);
        close(stderr_pipe[1]);

        // Change work dir
        if (work_dir) {
            chdir(work_dir);
        }

        // Execute from memfd via /proc/self/fd/<N>
        if (envp) {
            execve(fd_path, argv, envp);
        } else {
            execv(fd_path, argv);
        }

        // If we get here, exec failed
        fprintf(stderr, "execve failed for %s: %s\n", fd_path, strerror(errno));
        _exit(127);
    }

    // ---- PARENT PROCESS ----
    close(slave_fd);        // Close slave side (only child uses it)
    close(stderr_pipe[1]);  // Close write end of stderr pipe
    close(mem_fd);

    // Store child info
    if (children_count < MAX_CHILDREN) {
        children[children_count].pid = pid;
        children[children_count].master_fd = master_fd;
        children[children_count].stderr_fd = stderr_pipe[0];
        children_count++;
    }

    // Make fds non-blocking for polling reads
    fcntl(master_fd, F_SETFL, O_NONBLOCK);
    fcntl(stderr_pipe[0], F_SETFL, O_NONBLOCK);

    LOGD("PTY exec succeeded: pid=%d, fd_path=%s, master_fd=%d", pid, fd_path, master_fd);

    // Free argv/envp
    for (int i = 0; argv[i]; i++) free(argv[i]);
    free(argv);
    if (envp) {
        for (int i = 0; envp[i]; i++) free(envp[i]);
        free(envp);
    }
    if (work_dir) {
        (*env)->ReleaseStringUTFChars(env, jWorkDir, work_dir);
    }

    return (jint)pid;
}

/*
 * Read available data from a child's PTY master (stdout).
 * ANSI escape sequences are stripped before returning.
 */
JNIEXPORT jstring JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeReadStdout(
    JNIEnv *env, jclass clazz, jint pid
) {
    int idx = find_child((pid_t)pid);
    if (idx < 0) return (*env)->NewStringUTF(env, "");

    char buf[4096];
    ssize_t n = read(children[idx].master_fd, buf, sizeof(buf) - 1);
    if (n <= 0) return (*env)->NewStringUTF(env, "");
    buf[n] = '\0';

    // Strip ANSI escape sequences from PTY output
    strip_ansi(buf, (int)n);

    return (*env)->NewStringUTF(env, buf);
}

/*
 * Read available data from a child's stderr pipe.
 */
JNIEXPORT jstring JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeReadStderr(
    JNIEnv *env, jclass clazz, jint pid
) {
    int idx = find_child((pid_t)pid);
    if (idx < 0) return (*env)->NewStringUTF(env, "");

    char buf[4096];
    ssize_t n = read(children[idx].stderr_fd, buf, sizeof(buf) - 1);
    if (n <= 0) return (*env)->NewStringUTF(env, "");
    buf[n] = '\0';
    return (*env)->NewStringUTF(env, buf);
}

/*
 * Wait for child process and return exit code.
 * Cleans up the child entry.
 */
JNIEXPORT jint JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeWaitFor(
    JNIEnv *env, jclass clazz, jint pid
) {
    int status = 0;
    waitpid((pid_t)pid, &status, 0);

    int idx = find_child((pid_t)pid);
    if (idx >= 0) {
        close(children[idx].master_fd);
        close(children[idx].stderr_fd);
        // Remove from array
        children[idx] = children[children_count - 1];
        children_count--;
    }

    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    return -1;
}

/*
 * Kill a child process.
 */
JNIEXPORT void JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeKill(
    JNIEnv *env, jclass clazz, jint pid
) {
    LOGD("Killing child pid=%d", pid);
    kill((pid_t)pid, SIGTERM);

    // Give it 1 second, then SIGKILL
    usleep(1000000);
    int status;
    if (waitpid((pid_t)pid, &status, WNOHANG) == 0) {
        kill((pid_t)pid, SIGKILL);
        waitpid((pid_t)pid, &status, 0);
    }

    int idx = find_child((pid_t)pid);
    if (idx >= 0) {
        close(children[idx].master_fd);
        close(children[idx].stderr_fd);
        children[idx] = children[children_count - 1];
        children_count--;
    }
}

/*
 * Check if a child process is still alive.
 */
JNIEXPORT jboolean JNICALL
Java_com_zrokapp_mobile_NativeExec_nativeIsAlive(
    JNIEnv *env, jclass clazz, jint pid
) {
    int status;
    pid_t result = waitpid((pid_t)pid, &status, WNOHANG);
    if (result == 0) return JNI_TRUE;   // still running
    return JNI_FALSE;
}
