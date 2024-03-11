#include "diskimg.h"

const char *bootvhd_name="MTX512  VHD";
const char *bootrom_name="MTX512  ROM";

char *autoboot()
{
        char *result=0;
        diskimg_mount(bootvhd_name,0);
        LoadROM(bootrom_name);
        return(result);
}

