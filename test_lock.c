#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
char array[2048];

    if (mlock((const void *)array, sizeof(array)) == -1) {
            perror("mlock: ");
            return -1;
    }

    printf("success to lock stack mem at: %p, len=%zd\n",
                    array, sizeof(array));

    sleep(240);
    if (munlock((const void *)array, sizeof(array)) == -1) {
            perror("munlock: ");
            return -1;
    }

    printf("success to unlock stack mem at: %p, len=%zd\n",
                    array, sizeof(array));

    return 0;
}
