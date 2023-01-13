﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Threading;

namespace turbolink
{
    class Usbio
    {

        Edio edio;

        public Usbio(Edio edio)
        {
            this.edio = edio;
        }

        public void copyFile(string src, string dst)
        {
            byte[] src_data;
            src = src.Trim();
            dst = dst.Trim();

            if (File.GetAttributes(src).HasFlag(FileAttributes.Directory))
            {
                copyFolder(src, dst);
                return;
            }

            if (dst.EndsWith("/") || dst.EndsWith("\\"))
            {
                dst += Path.GetFileName(src);
            }

            Console.WriteLine("copy file: " + src + " to " + dst);

            if (src.ToLower().StartsWith("sd:"))
            {
                src = src.Substring(3);
                src_data = new byte[edio.fileInfo(src).size];

                edio.fileOpen(src, Edio.FAT_READ);
                edio.fileRead(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                src_data = File.ReadAllBytes(src);
            }

            if (src_data.Length > Edio.MAX_ROM_SIZE)
            {
                throw new Exception("File is too big");
            }


            if (dst.ToLower().StartsWith("sd:"))
            {
                dst = dst.Substring(3);
                edio.fileOpen(dst, Edio.FAT_CREATE_ALWAYS | Edio.FAT_WRITE);
                edio.fileWrite(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                File.WriteAllBytes(dst, src_data);
            }
        }

        public void makeDir(string path)
        {
            path = path.Trim();

            if (path.ToLower().StartsWith("sd:") == false)
            {
                throw new Exception("incorrect dir path: " + path);
            }
            Console.WriteLine("make dir: " + path);
            path = path.Substring(3);
            edio.dirMake(path);
        }

        void copyFolder(string src, string dst)
        {
            if (!src.EndsWith("/")) src += "/";
            if (!dst.EndsWith("/")) dst += "/";

            string[] dirs = Directory.GetDirectories(src);

            for (int i = 0; i < dirs.Length; i++)
            {
                copyFolder(dirs[i], dst + Path.GetFileName(dirs[i]));
            }


            string[] files = Directory.GetFiles(src);


            for (int i = 0; i < files.Length; i++)
            {
                copyFile(files[i], dst + Path.GetFileName(files[i]));
            }
        }


        public void appInstall(string path)
        {
            int resp;
            edio.fifoWR("*i");
            edio.fifoTxString(path);
            resp = edio.rx8();
            if (resp != 0)
            {
                throw new Exception("app instalation error: " + resp.ToString("X2"));
            }
        }

        public void appStart()
        {
            edio.fifoWR("*s");
        }

        public void test()
        {
            int resp;
            edio.fifoWR("*t");

            try
            {
                resp = edio.rx8();
            }
            catch (Exception)
            {
                throw new Exception("usb cmd timeout");
            }

            if (resp != 'k')
            {
                throw new Exception("usb cmd unexpected response: " + resp.ToString("X2"));
            }
        }
    

        public void reset()
        {
            int resp;
            edio.hostReset(Edio.HOST_RST);
            Thread.Sleep(10);
            edio.configReset();
            edio.hostReset(Edio.HOST_RST_OFF);

            resp = edio.rx8();
            if (resp != 'r')
            {
                throw new Exception("unexpected usb status: " + resp.ToString("X2"));
            }

        }

        public void vramDump(byte []vram, byte []palette)
        {
            int dump_addr;
            edio.fifoWR("*v");
            dump_addr = edio.rx32();

            edio.memRD(dump_addr, vram, 0, 0x10000);
            edio.memRD(dump_addr + 0x10000, palette, 0, 1024);
        }
        
    }
}
