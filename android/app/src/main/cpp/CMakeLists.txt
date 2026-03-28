cmake_minimum_required(VERSION 3.18.1)
project("exec_helper" C)

add_library(exec_helper SHARED exec_helper.c)

target_link_libraries(exec_helper
    android
    log
)
