using System;
using System.Drawing.Imaging;
using System.IO;
using System.Threading;

namespace turbolink
{
    class CmdProcessor
    {


        static Edio edio;
        static Usbio usb;
        static bool arst_off;
        public static void start(string[] args, Edio io)
        {

            edio = io;
            usb = new Usbio(edio);
            arst_off = false;

            string usr_fpga = null;
            string usr_rom = null;


            for (int i = 0; i < args.Length; i++)
            {
                string cmd = args[i].ToLower().Trim();


                if (cmd.Equals("-netgate"))//usb no network bridge
                {
                    NetGate.start(io);
                }

                if (cmd.Equals("-rstoff"))
                {
                    arst_off = true;//turn off automatic reset controller.
                }

                if (cmd.Equals("-reset"))
                {
                    edio.hostReset(Edio.HOST_RST);
                    continue;
                }

                if (cmd.Equals("-rtype"))
                {
                    cmd_forceRstType(args[i + 1]);
                    i += 1;
                }

                if (cmd.Equals("-recovery"))
                {
                    cmd_recovery();
                    continue;
                }

                if (cmd.Equals("-update"))//as recovery, but executed from bootloader. works without power down down
                {
                    cmd_update();
                    return;//usb link will be lost. no more commands can be executed
                }

                if (cmd.Equals("-appmode"))
                {
                    cmd_exitServiceMode();
                    continue;
                }

                if (cmd.Equals("-sermode"))
                {
                    cmd_enterServiceMode();
                    continue;
                }

                if (cmd.Equals("-flawr"))
                {
                    cmd_flashWrite(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }

                if (cmd.Equals("-flard"))
                {
                    cmd_flashRead(args[i + 1], args[i + 2], args[i + 3]);
                    i += 3;
                    continue;
                }


                if (cmd.Equals("-rtcset"))
                {
                    edio.rtcSet(DateTime.Now);
                    continue;
                }


                if (cmd.StartsWith("-memprint"))
                {
                    cmd_memPrint(args[i + 1], args[i + 2]);
                    i += 2;
                }

                if (cmd.StartsWith("-memwr"))
                {
                    cmd_memWrite(args[i + 1], args[i + 2]);
                    i += 2;
                }

                if (cmd.StartsWith("-memrd"))
                {
                    cmd_memRead(args[i + 1], args[i + 2], args[i + 3]);
                    i += 3;
                }


                if (cmd.Equals("-verify"))
                {
                    cmd_verify(args[i + 1], args[i + 2], args[i + 3]);
                    i += 3;
                    continue;
                }

                if (cmd.EndsWith("-fpga"))
                {
                    cmd_loadFpga(args[i + 1]);
                    i += 1;
                    continue;
                }

                if (cmd.EndsWith(".pce"))
                {
                    usr_rom = args[i];
                }

                if (isMapperFile(cmd))
                {
                    usr_fpga = args[i];
                    continue;
                }

                if (cmd.Equals("-cp"))
                {
                    usb.copyFile(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }

                if (cmd.Equals("-mkdir"))
                {
                    usb.makeDir(args[i + 1]);
                    i += 1;
                    continue;
                }

                if (cmd.Equals("-screen"))
                {
                    //this stuff only for taking screenshots for using in manual
                    cmd_screenshot();
                    continue;
                }


            }

            if (usr_rom != null)
            {
                cmd_loadGame(usr_rom, usr_fpga);
            }

            Thread.Sleep(10);//make sure that reset isn't toggled too fast
            edio.hostReset(Edio.HOST_RST_OFF);
            Console.WriteLine("");
        }


        static int getNum(string num)
        {

            if (num.ToLower().Contains("0x"))
            {
                return Convert.ToInt32(num, 16);
            }
            else
            {
                return Convert.ToInt32(num);
            }

        }

        static byte[] getFileData(string path)
        {
            byte[] data = null;

            if (path.ToLower().StartsWith("efu:"))
            {
                string efu_path = path.Substring(4);
                efu_path = efu_path.Substring(0, efu_path.IndexOf("//"));

                string file_path = path.Substring(path.IndexOf("//") + 2);
                file_path = file_path.Replace("\\", "/");

                data = new Datafile(efu_path).getFileData(file_path);

            }
            else
            {
                data = File.ReadAllBytes(path);
            }


            return data;
        }

        static void rstControl(int addr)
        {

            if (arst_off) return;

            if (addr < Edio.SIZE_ROM)
            {
                edio.hostReset(Edio.HOST_RST);
            }
        }

        static void cmd_memPrint(string addr_str, string len_str)
        {
            int addr;
            int len;

            addr = getNum(addr_str);
            len = getNum(len_str);
            if (len > 8192) len = 8192;
            if (len % 16 != 0)
            {
                len = (len / 16 + 1) * 16;
            }

            rstControl(addr);
            byte[] buff = new byte[len];
            edio.memRD(addr, buff, 0, buff.Length);

            for (int i = 0; i < buff.Length; i += 16)
            {
                Console.WriteLine(BitConverter.ToString(buff, i, 16));
            }
        }

        static void cmd_verify(string path, string addr_str, string len_str)
        {
            int addr;
            int len;
            Console.Write("Memory verification...");

            addr = getNum(addr_str);
            len = getNum(len_str);

            rstControl(addr);
            byte[] mdata = new byte[len];
            edio.memRD(addr, mdata, 0, mdata.Length);


            byte[] fdata = File.ReadAllBytes(path);

            int cmp_len = Math.Min(mdata.Length, fdata.Length);
            for (int i = 0; i < cmp_len; i++)
            {
                if (mdata[i] != fdata[i]) throw new Exception("verification error at " + i);
            }

            Console.WriteLine("ok");
        }

        static void cmd_memRead(string path, string addr_str, string len_str)
        {
            int addr;
            int len;
            Console.Write("Memory read...");

            addr = getNum(addr_str);
            len = getNum(len_str);

            rstControl(addr);
            byte[] data = new byte[len];
            edio.memRD(addr, data, 0, data.Length);
            File.WriteAllBytes(path, data);

            Console.WriteLine("ok");
        }

        static void cmd_memWrite(string path, string addr_str)
        {
            int addr = 0;
            Console.Write("Memory write...");

            addr = getNum(addr_str);

            rstControl(addr);
            byte[] data = File.ReadAllBytes(path);
            edio.memWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }


        static void cmd_loadFpga(string path)
        {
            byte[] fpga = File.ReadAllBytes(path);

            rstControl(0);//force reset
            edio.flush();

            Console.Write("FPGA loading...");
            edio.fpgInit(fpga);
            Console.WriteLine("ok");
        }




        static void cmd_recovery()
        {

            Console.Write("EDIO core recovery...");
            edio.recovery();
            Console.WriteLine("ok");
        }

        static void cmd_update()
        {
            Console.Write("EDIO core update...");

            byte[] buff = new byte[4];
            edio.flaRD(Edio.ADDR_FLA_ICOR + 4, buff, 0, buff.Length);

            int crc = (buff[0] << 0) | (buff[1] << 8) | (buff[2] << 16) | (buff[3] << 24);
            edio.updExec(Edio.ADDR_FLA_ICOR, crc);

            Console.WriteLine("ok");
        }

        static void cmd_exitServiceMode()
        {
            Console.Write("Exit service mode...");
            edio.exitServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_enterServiceMode()
        {
            Console.Write("Enter service mode...");
            edio.enterServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_flashWrite(string path, string addr_str)
        {
            Console.Write("Flash programming...");

            int addr = getNum(addr_str);

            byte[] data = getFileData(path);

            edio.flaWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }

        static void cmd_flashRead(string path, string addr_str, string len_str)
        {

            Console.Write("Flash read...");

            int addr = getNum(addr_str);
            int len = getNum(len_str);

            byte[] data = new byte[len];

            edio.flaRD(addr, data, 0, data.Length);
            File.WriteAllBytes(path, data);

            Console.WriteLine("ok");
        }

        static void cmd_forceRstType(string type)
        {
            if (type.Equals("hard"))
            {
                edio.forceRstType(Edio.HOST_RST);
            }

            if (type.Equals("soft"))
            {
                edio.forceRstType(Edio.HOST_RST);
            }

            if (type.Equals("off"))
            {
                edio.forceRstType(Edio.HOST_RST_OFF);
            }
        }

        static void cmd_loadGame(string game_path, string fpga_path)
        {

            Console.WriteLine("Load game...");

            string usb_home = "sd:usb-games";

            if (!arst_off)
            {
                usb.reset();
            }

            usb.makeDir(usb_home);

            if (fpga_path != null)
            {
                usb_home += "/" + Path.GetFileName(game_path) + ".fpgrom";
                usb.makeDir(usb_home);
            }

            string game_dst = usb_home + "/" + Path.GetFileName(game_path);

            long time = DateTime.Now.Ticks;

            usb.copyFile(game_path, game_dst);

            time = (DateTime.Now.Ticks - time) / 10000;
            Console.WriteLine("copy time: " + time);

            if (fpga_path != null)
            {
                string fpga_dst = usb_home + "/" + Path.GetFileName(fpga_path);
                usb.copyFile(fpga_path, fpga_dst);
            }

            usb.appInstall(game_dst.Substring(3));
            usb.appStart();

            edio.getStatus();
            Console.WriteLine("ok");
        }

        static void cmd_screenshot()
        {
            byte[] vram = new byte[0x10000];
            byte[] palette = new byte[1024];

            usb.vramDump(vram, palette);
            MenuImage.makeImage(DateTime.Now.ToString().Replace(":", "").Replace(" ", "_").Replace(".", "-").Replace("/", "-") + ".png", vram, palette);
        }

        static bool isMapperFile(string path)
        {
            string file_ext = Path.GetExtension(path).ToLower();

            if (file_ext.Length != 4)
            {
                return false;
            }

            if (file_ext.EndsWith(".rbf"))
            {
                return true;
            }

            if (file_ext[0] != '.') return false;
            if (file_ext[1] != 'x') return false;
            try
            {
                int id = Convert.ToInt32(file_ext.Substring(2), 16);
                //Console.WriteLine("id: " + id.ToString("X2"));
            }
            catch
            {
                return false;
            }

            return true;
            //Console.WriteLine();
            //return path.EndsWith(".rbf");
        }

    }
}
