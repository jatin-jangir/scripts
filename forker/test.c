#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

void my_function(void) {
    printf("Hello from user-space function!\n");
}

int main() {
    int fd;
    char buffer[1024];
    char write_buffer[1024];

    fd = open("/dev/user_func_exec", O_RDWR);
    if (fd < 0) {
        perror("Failed to open the device");
        return -1;
    }

    // Prepare the write buffer with PID and function address
    snprintf(write_buffer, sizeof(write_buffer), "%d %lx", getpid(), (unsigned long)&my_function);

    // Write to the device
    if (write(fd, write_buffer, strlen(write_buffer)) < 0) {
        perror("Failed to write to the device");
        close(fd);
        return -1;
    }
    fork();
    // Read from the device to trigger the function execution
   // if (read(fd, buffer, sizeof(buffer)) < 0) {
     //   perror("Failed to read from the device");
      //  close(fd);
      //  return -1;
   // }

    printf("Final statement\n");

    close(fd);
    return 0;
}
