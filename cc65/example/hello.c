#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <dirent.h>

bool
copy_test(char *src, char *dest)
{
    FILE *in, *out;
    bool ret = false;
    
    printf("Copying from %s to %s\n", src, dest);
    if (in = fopen(src, "r")) {
        if (out = fopen(dest, "w")) {
            ret = true;
            for (;;) {
                int c = fgetc(in);
                if (c < 0) {
                    break;
                }
                fputc(c, out);
            }
            fclose(out);
        }
        fclose(in);
    }
    
    return ret;
}

bool
read_test(char *src)
{
    FILE *fp;
   
    fp = fopen(src, "r");
    if (fp != NULL) {
        printf("Reading; fp @ %p:", fp);
        for(;;) {
            int c = fgetc(fp);
            if (c < 0) {
                break;
            }
            putchar(c);
        }
        fclose(fp);
        return true;
    }

    return false;

}    

bool
write_test(char *dest)
{
    FILE *fp;
    
    printf("Writing test.txt.\n");
    fp = fopen(dest, "w");
    if (fp != NULL) {
        fwrite("test!", 1, 5, fp);
        fclose(fp);
        return true;
    }
    
    return false;
}

int 
main()
{
    char c = 0;
    struct DIR *dir;
    
    putchar(12);  // cls
    puts("Hello world!");
    puts("Waiting for IEC init to complete.");
    
    if (dir = opendir("0:")) {
        struct dirent *dirent;
        puts("Directory:");
        for (;;) {
            if (dirent = readdir(dir)) {
                puts(dirent->d_name);
                continue;
            }
            break;
        }
        closedir(dir);
    }
    
    
        
    do {
        if (!write_test("0:test.txt")) {
            printf("Write test failed.\n");
            break;
        }

        if (!read_test("0:test.txt")) {
            printf("Read test failed.\n");
            break;
        }

        if (!copy_test("test.txt", "copy.txt")) {
            printf("Copy test failed.\n");
            break;
        }
        
        if (!read_test("copy.txt")) {
            printf("Read test failed.\n");
            break;
        }
        
        
        if (remove("copy.txt") != 0) {
            printf("delete failed.\n");
            break;
        }
        
        
    } while (false);
    
    puts("");
    printf("Testing getchar(); press CTRL-C to exit.\n");
    while (c != 3) {
        c = getchar();
        putchar(c);
    }
    
    return 0;
}
