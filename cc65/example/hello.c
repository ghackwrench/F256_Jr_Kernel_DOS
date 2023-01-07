#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

      


bool
read_test()
{
    FILE *fp;
    char buf[5];
   
    fp = fopen("test.txt", "r");
    if (fp != NULL) {
        puts("Reading:");
        for(;;) {
            int i;
            int units = fread(&buf, sizeof(buf), 1, fp);
            if (units <= 0) {
                break;
            }
            for (i = 0; i < sizeof(buf); i++) {
                putchar(buf[i]);
            }
            break;
        }
        fclose(fp);
        return true;
    }

    return false;

}    

bool
write_test()
{
    FILE *fp;
    
    printf("Writing test.txt.\n");
    printf("Note: IEC drives take a while to recover from reset...\n");
    fp = fopen("test.txt", "w");
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
    
    putchar(12);  // cls
    printf("Hello world!\n");
    
    if (write_test()) {
        printf("Write test succeeded.\n");
        read_test();
        puts("");
    }
    
    printf("Testing getchar(); press CTRL-C to exit.\n");
    while (c != 3) {
        c = getchar();
        putchar(c);
    }
    
    return 0;
}
