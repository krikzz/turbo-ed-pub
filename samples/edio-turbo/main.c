
#include "main.h"

void deviceID();
void romPath();
void romRead();
void fileRead();
void fileRead();
void fileWrite();
void fileToRom();
void folderList();
void sysTimer();
void usbWrite();
void usbRead();

static u8 rom_path[512];

void main() {

    sysInit();
    ed_init();

    gConsPrintCX("EverDrive IO sample");
    gSetXY(0, 2);

    deviceID();//device model identification
    romPath(); //get current rom path
    romRead(); //read rom memory
    fileRead(); //read from file
    fileWrite(); //write to the file
    fileToRom(); //fast dma transfer from file to the rom memory
    folderList(); //print list of files in the folder
    sysTimer(); //system ms timer

    gConsPrint("");
    gConsPrint("press any key when ready to test usb");
    while (sysJoyRead() == 0);
    gCleanScreen();

    usbWrite(); //tx via usb to pc
    usbRead(); //rx from via usb from pc

    while (1);
}

void deviceID() {

    u8 resp[4];

    //0: STATUS_KEY
    //1: PROTOCOL_ID
    //2: DEVID
    //3: EDIO_STATUS
    ed_cmd_status(resp);

    gConsPrint("dev ID   : ");
    gAppendHex8(resp[2]);
    gConsPrint("dev name : ");

    switch (resp[2]) {
        case DEVID_TE_PRO:
            gAppendString("Turbo EverDrive PRO");
            break;
        case DEVID_TE_CORE:
            gAppendString("Turbo EverDrive CORE");
            break;
        default:
            gAppendString("Unknown");
            break;
    }

}

void romPath() {

    ed_cmd_rom_path(rom_path, 0); //buffer size should be not less than 512B

    gConsPrint("rom path : ");
    gAppendString_ML(rom_path, 27);

}

void romRead() {

    u8 buff[12];

    gConsPrint("rom read : ");
    ed_mem_rdd(16, buff, sizeof (buff)); //read rom memory at offset 16
    gAppendHex(buff, sizeof (buff));
}

void fileRead() {

    u8 resp;
    u8 buff[12];
    u32 size;

    resp = ed_cmd_file_open("edturbo/menu.dat", FA_READ);
    if (resp)return; //error
    size = ed_cmd_file_available();
    resp = ed_cmd_file_read(buff, sizeof (buff));
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error

    gConsPrint("file read: ");
    gAppendHex(buff, sizeof (buff));
    gConsPrint("file size: 0x");
    gAppendHex32(size);
}

void fileWrite() {

    u8 resp;
    u8 buff[] = {'h', 'e', 'l', 'l', 'o', ' ', 't', 'e', 'x', 't'};

    gConsPrint("file write...");
    //create "test_file.txt" in the root of SD and write buff to the file.
    resp = ed_cmd_file_open("test_file.txt", FA_WRITE | FA_CREATE_ALWAYS);
    if (resp)return; //error
    resp = ed_cmd_file_write(buff, sizeof (buff));
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error
    gAppendString("ok");

}

void fileToRom() {

    u8 resp;
    u32 size;

    gConsPrint("read file to rom...");

    resp = ed_cmd_file_open("edturbo/menu.dat", FA_READ);
    if (resp)return; //error
    size = ed_cmd_file_available();
    resp = ed_cmd_file_read_mem(0x20000, size); //write whole file to the rom memory at offset 0x20000
    if (resp)return; //error
    resp = ed_cmd_file_close();
    if (resp)return; //error

    gAppendString("ok");
}

void folderList() {

    u8 resp;
    u16 size;
    u8 i;
    FileInfo inf;
    u8 name_buff[16 + 1];

    inf.file_name = name_buff;

    gConsPrint("");
    gConsPrint("get folder list...");

    resp = ed_cmd_dir_load("edturbo", 0); //get list of files in system folder
    if (resp)return; //error
    ed_cmd_dir_get_size(&size);

    gAppendString("dir size: ");
    gAppendNum(size);

    ed_cmd_dir_get_recs(0, size, sizeof (name_buff) - 1);

    for (i = 0; i < size && i < 8; i++) {

        resp = ed_rx_next_rec(&inf);
        if (resp)return; //error
        gConsPrint("[");
        gAppendString(inf.file_name);
        gAppendString("]");

        if (inf.is_dir) {
            gAppendString("...dir");
        } else {
            gAppendString("...file");
        }
    }

    gConsPrint("");
}

void sysTimer() {

    u8 i;
    u16 time;
    gConsPrint("one frame time: ");

    gVsync(); //vsync alignment
    time = ed_get_ticks();
    for (i = 0; i < 10; i++) {//10 iteration for accurate measurement
        gVsync();
    }
    time = ed_get_ticks() - time;
    time /= 10;

    gAppendNum(time);
    gAppendString("ms");

}

void usbWrite() {//send strings to the virtual com-port. Use any serial terminal app to receive strings.

    gConsPrint("send test string to usb...");
    ed_cmd_usb_wr("test string\n", 12);

}

void usbRead() {//receive strings from virtual-com and print to the screen. use string-read.bat for string sending

    u8 char_val;

    gConsPrint("waiting for input string from usb...");
    gConsPrint("");

    while (1) {

        //single byte communication is very slow. 
        //use larger blocks for real applications but not more than SIZE_FIFO
        ed_fifo_rd(&char_val, 1);

        if (char_val == '\n') {
            gConsPrint("");
        } else {
            gAppendChar(char_val);
        }
    }


}


