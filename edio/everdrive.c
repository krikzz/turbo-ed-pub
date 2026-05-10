
#include "main.h"

#define CMD_STATUS      0x10
#define CMD_GET_MODE    0x11
#define CMD_IO_RST      0x12
#define CMD_GET_VDC     0x13
#define CMD_RTC_GET     0x14
#define CMD_RTC_SET     0x15
#define CMD_FLA_RD      0x16
#define CMD_FLA_WR      0x17
#define CMD_FLA_WR_SDC  0x18
#define CMD_MEM_RD      0x19
#define CMD_MEM_WR      0x1A
#define CMD_MEM_SET     0x1B
#define CMD_MEM_TST     0x1C
#define CMD_MEM_CRC     0x1D
#define CMD_FPG_USB     0x1E
#define CMD_FPG_SDC     0x1F
#define CMD_FPG_FLA     0x20
#define CMD_CD_MOUNT    0x21
#define CMD_USB_WR      0x22
#define CMD_FIFO_WR     0x23
#define CMD_UART_WR     0x24
#define CMD_REINIT      0x25
#define CMD_SYS_INF     0x26
#define CMD_GAME_CTR    0x27
#define CMD_UPD_EXEC    0x28
#define CMD_HOST_RST    0x29
//#define CMD_USB_STATUS  0x2A
#define CMD_RAPP_SET    0x2B
#define CMD_SUB_STATUS  0x2C
#define CMD_BRAM_SAVE   0x2D//force bram moving to file if it was modified
#define CMD_EFU_UNPACK  0x2E//install menu to sd 
#define CMD_EFU_UPDATE  0x2F//write efu to flash
#define CMD_CALC_FILT   0x30
#define CMD_ROM_PATH    0x31

#define CMD_DISK_INIT   0xC0
#define CMD_DISK_RD     0xC1
#define CMD_DISK_WR     0xC2
#define CMD_F_DIR_OPN   0xC3
#define CMD_F_DIR_RD    0xC4
#define CMD_F_DIR_LD    0xC5
#define CMD_F_DIR_SIZE  0xC6
#define CMD_F_DIR_PATH  0xC7
#define CMD_F_DIR_GET   0xC8
#define CMD_F_FOPN      0xC9
#define CMD_F_FRD       0xCA
#define CMD_F_FRD_MEM   0xCB
#define CMD_F_FWR       0xCC
#define CMD_F_FWR_MEM   0xCD
#define CMD_F_FCLOSE    0xCE
#define CMD_F_FPTR      0xCF
#define CMD_F_FINFO     0xD0
#define CMD_F_FCRC      0xD1
#define CMD_F_DIR_MK    0xD2
#define CMD_F_DEL       0xD3
#define CMD_F_SEEK_IDX  0xD4
#define CMD_F_AVB       0xD5
#define CMD_F_FCP       0xD6
#define CMD_F_SEEK_PAT  0xD8 //seek data pattern


void ed_init_asm();
void ed_start_app_asm();
void ed_fifo_rd_asm();
void ed_fifo_wr_asm();
void ed_cmd_tx_asm();


u8 ed_fifo_rd_skip(u16 len);
u32 ed_min(u32 v1, u32 v2);
void ed_rx_file_info(FileInfo *inf);
void ed_halt_asm();
void ed_halt(u8 stat_req);
void ed_run_dma();
void ed_fifo_flush();
//****************************************************************************** public
#pragma codeseg ("BNK00")

void ed_init() {

    ed_init_asm();
    ed_fifo_flush();
}

u8 ed_fifo_busy() {

    return (REG_FIFO_STAT & FIFO_CPU_RXF) ? 1 : 0;
}

void ed_fifo_rd(void *data, u16 len) {

    while (len) {

        zp_dst = data;
        zp_len = len;
        if (zp_len > 256)zp_len = 256;
        ed_fifo_rd_asm(); //can transfer 256 bytes max
        if (len <= 256)return;
        len -= 256;
        (u8 *) data += 256;
    }
}

void ed_fifo_wr(void *data, u16 len) {

    if (len == 0)return;
    zp_src = data;
    zp_dst = (u8 *) REGA_FIFO_DATA;
    zp_len = len;
    sys_mem_to_reg_asm();
}

u8 ed_check_status() {

    u8 resp[4];

    ed_cmd_status(resp);

    if (resp[0] != STATUS_KEY) {
        return ERR_UNXP_STAT;
    }

    return resp[3];
}

void ed_tx_string(u8 *string) {

    u16 str_len = 0;
    u8 *ptr = string;

    while (*ptr++ != 0)str_len++;

    ed_fifo_wr(&str_len, 2);
    ed_fifo_wr(string, str_len);
}

void ed_rx_string(u8 *string) {

    u16 str_len;

    ed_fifo_rd(&str_len, 2);

    if (string == 0) {
        ed_fifo_rd_skip(str_len);
        return;
    }

    string[str_len] = 0;

    ed_fifo_rd(string, str_len);
}

u8 ed_rx_next_rec(FileInfo *inf) {

    u8 resp;

    ed_fifo_rd(&resp, 1);
    if (resp)return resp;

    ed_rx_file_info(inf);

    return 0;
}

u16 ed_get_ticks() {

    REG_TIMER = 0;
    asm("nop");
    return REG_TIMER;
}

/*
void ed_set_ctrl(u8 ctrl) {

    u32 cfg_addr = ADDR_CFG + 256 - sizeof (CartCfg);
    CartCfg *cfg = 0;

    cfg_addr += inStrcutAddr(cfg, &cfg->ctrl);

    ed_cmd_mem_wr(cfg_addr, &ctrl, 1);
}*/

void ed_app_start(CartCfg *cfg) {

    extern u8 ed_halt_arg;
    u32 addr = ADDR_CFG + 256 - sizeof (CartCfg);
    u32 size = sizeof (CartCfg);
    u8 ack = 0xaa; //mcu will wait for ack byte before than start mem wr

    ed_cmd_tx(CMD_MEM_WR);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&size, 4);
    ed_fifo_wr(&ack, 1);
    ed_fifo_wr(cfg, size);

    ed_halt_arg = STATUS_CMD_OK;
    ed_start_app_asm();
}

u8 ed_cmd_rapp_set(u32 addr) {

    u8 exec = 0; //0 set rapp, !0 reset status

    ed_cmd_tx(CMD_RAPP_SET);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&exec, 1);

    return ed_check_status();
}

void ed_cmd_rapp_cln() {

    u32 addr = 0;
    u8 exec = 1; //0 set rapp, !0 reset status

    ed_cmd_tx(CMD_RAPP_SET);
    ed_fifo_wr(&addr, 4); //address val does not matter
    ed_fifo_wr(&exec, 1);
}

u8 ed_cmd_cd_mount(u8 *path) {

    ed_cmd_tx(CMD_CD_MOUNT);
    ed_tx_string(path);
    return ed_check_status();
}

void ed_cmd_sys_inf(SysInfoIO *inf) {
    ed_cmd_tx(CMD_SYS_INF);
    ed_fifo_rd(inf, sizeof (SysInfoIO));
}

u8 ed_cmd_sub_status(u8 stat_req) {

    u8 val;
    ed_cmd_tx(CMD_SUB_STATUS);
    ed_fifo_wr(&stat_req, 1);
    ed_fifo_rd(&val, 1);
    return val;
}

void ed_cmd_get_vdc(Vdc *vdc) {

    ed_cmd_tx(CMD_GET_VDC);
    ed_fifo_rd(vdc, sizeof (Vdc));

}

void ed_set_mem_addr(u32 addr) {

    REG_MEM_ADDR = addr >> 0;
    REG_MEM_ADDR = addr >> 8;
    REG_MEM_ADDR = addr >> 16;
    REG_MEM_ADDR = addr >> 24;
}

u8 ed_cmd_bram_save() {

    ed_cmd_tx(CMD_BRAM_SAVE);
    return ed_check_status();
}

void ed_cmd_game_ctr() {
    ed_cmd_tx(CMD_GAME_CTR);
}

u8 ed_cmd_fpga_init(u8 *path) {

    u8 resp;
    u32 len;

    resp = ed_cmd_file_open(path, FA_READ);
    if (resp)return resp;

    len = ed_cmd_file_available();

    ed_cmd_tx(CMD_FPG_SDC);
    ed_fifo_wr(&len, 4);
    ed_halt(STATUS_FPG_OK); //fpg ok flag will be reset only after fpga reconfig

    ed_fifo_flush();

    return ed_check_status();
}

void ed_cmd_reboot() {

    ed_cmd_tx(CMD_REINIT);
    ed_halt(STATUS_CFG_OK | STATUS_FPG_OK | STATUS_REBOOT);
}

u8 ed_cmd_efu_unpack() {

    ed_cmd_tx(CMD_EFU_UNPACK);
    return ed_check_status();
}

u8 ed_cmd_efu_update(u8 *path) {

    ed_cmd_tx(CMD_EFU_UPDATE);
    ed_tx_string(path);
    return ed_check_status();
}

u8 ed_cmd_fla_wr_sdc(u32 addr, u32 len) {

    ed_cmd_tx(CMD_FLA_WR_SDC);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);
    return ed_check_status();
}

void ed_cmd_upd_exec(u32 addr, u32 crc) {

    ed_cmd_tx(CMD_UPD_EXEC);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&crc, 4);
    ed_halt(STATUS_CFG_OK | STATUS_FPG_OK | STATUS_REBOOT);
}

void ed_cmd_rtc_get(RtcTime *time) {

    ed_cmd_tx(CMD_RTC_GET);
    ed_fifo_rd(time, sizeof (RtcTime));
}

void ed_cmd_rtc_set(RtcTime *time) {

    ed_cmd_tx(CMD_RTC_SET);
    ed_fifo_wr(time, sizeof (RtcTime));
}

void ed_cmd_usb_wr(void *data, u16 len) {

    ed_cmd_tx(CMD_USB_WR);
    ed_fifo_wr(&len, 2);
    ed_fifo_wr(data, len);
}

void ed_cmd_calc_filt(FiltCfg *cfg, FiltPoly *poly) {

    ed_cmd_tx(CMD_CALC_FILT);
    ed_fifo_wr(cfg, sizeof (FiltCfg));
    ed_fifo_rd(poly, sizeof (FiltPoly));
}

u8 ed_cmd_rom_path(u8 *path, u8 path_type) {

    ed_cmd_tx(CMD_ROM_PATH);
    ed_fifo_wr(&path_type, 1); //0-rom, 1-cue
    ed_rx_string(path);
    return ed_check_status();
}
//****************************************************************************** private

void ed_halt(u8 stat_req) {

    extern u8 ed_halt_arg;
    ed_halt_arg = stat_req;
    ed_halt_asm();
}

void ed_run_dma() {
    ed_halt(STATUS_CMD_OK);
}

u8 ed_fifo_rd_skip(u16 len) {

    u8 tmp;

    while (len--) {

        while ((REG_FIFO_STAT & FIFO_CPU_RXF));
        tmp = REG_FIFO_DATA;
    }

    return 0;
}

u32 ed_min(u32 v1, u32 v2) {

    if (v1 < v2) {
        return v1;
    } else {
        return v2;
    }
}

void ed_rx_file_info(FileInfo *inf) {

    ed_fifo_rd(inf, 9);
    ed_rx_string(inf->file_name);
    inf->is_dir &= AT_DIR;
}

void ed_fifo_flush() {

    vu8 tmp;
    REG_FIFO_DATA = 0;
    asm("nop");
    REG_FIFO_DATA = 0;
    while ((REG_FIFO_STAT & FIFO_CPU_RXF) == 0) {
        tmp = REG_FIFO_DATA;
    }
}
//****************************************************************************** cmd var

void ed_cmd_tx(u8 cmd) {

    /*
    u8 buff[4];

    buff[0] = '+';
    buff[1] = '+' ^ 0xff;
    buff[2] = cmd;
    buff[3] = cmd ^ 0xff;

    ed_fifo_wr(buff, sizeof (buff));*/

    zp_cmd = cmd;
    ed_cmd_tx_asm();
}

void ed_cmd_status(void *status) {
    
    //0: STATUS_KEY
    //1: PROTOCOL_ID
    //2: DEVID
    //3: EDIO_STATUS
    ed_cmd_tx(CMD_STATUS);
    ed_fifo_rd(status, 4);
}
//****************************************************************************** disk io

u8 ed_cmd_disk_init() {

    ed_cmd_tx(CMD_DISK_INIT);
    return ed_check_status();
}

u8 ed_cmd_file_open(u8 *path, u8 mode) {

    if (*path == 0)return ERR_NULL_PATH;
    ed_cmd_tx(CMD_F_FOPN);
    ed_fifo_wr(&mode, 1);
    ed_tx_string(path);
    return ed_check_status();
}

u8 ed_cmd_file_close() {

    ed_cmd_tx(CMD_F_FCLOSE);
    return ed_check_status();
}

u8 ed_cmd_file_read(void *dst, u32 len) {

    u8 resp;
    u32 block;
    u8 *dst8 = (u8 *) dst;

    while (len) {

        block = ed_min(512, len);

        ed_cmd_tx(CMD_F_FRD); //we can read up to 4096 in single block. but reccomended not more than 512 to avoid fifo overload
        ed_fifo_wr(&block, 4);

        ed_fifo_rd(&resp, 1);
        if (resp)return resp;

        ed_fifo_rd(dst8, block);

        len -= block;
        dst8 += block;
    }

    return 0;
}

u8 ed_cmd_file_read_mem(u32 addr, u32 len) {

    if (len == 0)return 0;
    ed_cmd_tx(CMD_F_FRD_MEM);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);

    ed_run_dma();

    return ed_check_status();
}

u8 ed_cmd_file_write(void *src, u32 len) {

    u8 resp;
    u32 block;
    u8 *src8 = (u8 *) src;

    ed_cmd_tx(CMD_F_FWR);
    ed_fifo_wr(&len, 4);

    while (len) {

        block = ed_min(ACK_BLOCK_SIZE, len);

        ed_fifo_rd(&resp, 1);
        if (resp)return resp;

        ed_fifo_wr(src8, block);

        len -= block;
        src8 += block;
    }

    return ed_check_status();
}

u8 ed_cmd_file_write_mem(u32 addr, u32 len) {

    if (len == 0)return 0;
    ed_cmd_tx(CMD_F_FWR_MEM);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);

    //ed_dma_exec();
    ed_run_dma();

    return ed_check_status();
}

u8 ed_cmd_file_copy(u8 *src, u8 *dst, u8 dst_mode) {

    ed_cmd_tx(CMD_F_FCP);
    ed_fifo_wr(&dst_mode, 1);
    ed_tx_string(src);
    ed_tx_string(dst);
    return ed_check_status();
}

u32 ed_cmd_file_available() {

    u32 len[2];
    ed_cmd_tx(CMD_F_AVB);
    ed_fifo_rd(len, 8);

    return len[1];
}

u8 ed_cmd_file_set_ptr(u32 addr) {

    ed_cmd_tx(CMD_F_FPTR);
    ed_fifo_wr(&addr, 4);
    return ed_check_status();
}

u8 ed_cmd_file_info(u8 *path, FileInfo *inf) {

    u8 resp;

    ed_cmd_tx(CMD_F_FINFO);
    ed_tx_string(path);

    ed_fifo_rd(&resp, 1);
    if (resp)return resp;

    ed_rx_file_info(inf);

    return 0;
}

u8 ed_cmd_file_del(u8 *path) {

    ed_cmd_tx(CMD_F_DEL);
    ed_tx_string(path);
    return ed_check_status();
}

u8 ed_cmd_file_crc(u32 len, u32 *crc_base) {

    u8 resp;
    ed_cmd_tx(CMD_F_FCRC);
    ed_fifo_wr(&len, 4);
    ed_fifo_wr(crc_base, 4);

    ed_fifo_rd(&resp, 1);
    ed_fifo_rd(crc_base, 4);

    return resp;
}

u8 ed_cmd_file_seek_pat(u8 *pat, u8 psize, u32 fsize, u32 *paddr) {

    u8 resp;
    ed_cmd_tx(CMD_F_SEEK_PAT);
    ed_fifo_wr(&fsize, 4);
    ed_fifo_wr(&psize, 1);
    ed_fifo_wr(pat, psize);

    ed_fifo_rd(&resp, 1);
    ed_fifo_rd(paddr, 4);
    return resp;
}

u8 ed_cmd_dir_make(u8 *path) {

    ed_cmd_tx(CMD_F_DIR_MK);
    ed_tx_string(path);
    return ed_check_status();
}

u8 ed_cmd_dir_load(u8 *path, u8 dir_opt) {

    ed_cmd_tx(CMD_F_DIR_LD);
    ed_fifo_wr(&dir_opt, 1);
    ed_tx_string(path);

    return ed_check_status();
}

void ed_cmd_dir_get_size(u16 *size) {

    ed_cmd_tx(CMD_F_DIR_SIZE);
    ed_fifo_rd(size, 2);
}

void ed_cmd_dir_seek_idx(u16 *idx) {

    ed_cmd_tx(CMD_F_SEEK_IDX);
    ed_fifo_rd(idx, 2);
}

void ed_cmd_dir_get_recs(u16 start_idx, u16 amount, u16 max_name_len) {

    ed_cmd_tx(CMD_F_DIR_GET);
    ed_fifo_wr(&start_idx, 2);
    ed_fifo_wr(&amount, 2);
    ed_fifo_wr(&max_name_len, 2);
}

//****************************************************************************** memory io

void ed_cmd_mem_set(u8 val, u32 addr, u32 len) {

    ed_cmd_tx(CMD_MEM_SET);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);
    ed_fifo_wr(&val, 1);
    ed_run_dma();
}

u8 ed_cmd_mem_test(u8 val, u32 addr, u32 len) {

    u8 resp;

    ed_cmd_tx(CMD_MEM_TST);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);
    ed_fifo_wr(&val, 1);
    ed_run_dma();
    ed_fifo_rd(&resp, 1);

    return resp;
}

void ed_cmd_mem_rd(u32 addr, void *dst, u32 len) {

    u8 ack = 0;

    if (addr < ADDR_CFG) {
        ed_mem_rdd(addr, dst, len);
        return;
    }

    ed_cmd_tx(CMD_MEM_RD);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);

    if (addr < ADDR_CFG) {
        ed_run_dma();
    } else {
        ed_fifo_wr(&ack, 1); //move to ram app for access to memoey
    }

    ed_fifo_rd(dst, len);
}

void ed_cmd_mem_wr(u32 addr, void *src, u32 len) {

    u8 ack = 0;
    u32 block;

    if (addr < ADDR_CFG) {
        ed_mem_wrd(addr, src, len);
        return;
    }

    while (len) {

        if (addr < ADDR_CFG) {
            ack = 0xaa; //force to wait second ack byte befor dma
        }
        block = ed_min(len, ACK_BLOCK_SIZE);

        ed_cmd_tx(CMD_MEM_WR);
        ed_fifo_wr(&addr, 4);
        ed_fifo_wr(&block, 4);
        ed_fifo_wr(&ack, 1);
        ed_fifo_wr(src, block);

        if (ack == 0xaa) {
            ed_run_dma();
        }

        (u8*) src += block;
        addr += block;
        len -= block;
    }
}

void ed_cmd_mem_crc(u32 addr, u32 len, u32 *crc_base) {

    ed_cmd_tx(CMD_MEM_CRC);
    ed_fifo_wr(&addr, 4);
    ed_fifo_wr(&len, 4);
    ed_fifo_wr(crc_base, 4);
    ed_run_dma();

    ed_fifo_rd(crc_base, 4);
}

void ed_mem_rdd(u32 mem_addr, void *dst, u32 len) {

    ed_set_mem_addr(mem_addr);
    sysRegToMem((u16 *) REGA_MEM_DATA, dst, len);
}

void ed_mem_wrd(u32 mem_addr, void *src, u32 len) {

    ed_set_mem_addr(mem_addr | MEM_WP_MASK);
    sysMemToReg(src, (u16 *) REGA_MEM_DATA, len);
    ed_set_mem_addr(0);
}
