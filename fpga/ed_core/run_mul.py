import os
import sys
import subprocess
import shutil

USBTOOL = "../../edlink.py"

FPG_SRC = "fpga_mul/output_files/tecore"
APP_SRC = "../../mul-app/mul-app.pce"

ARGS = ["run", "--file", APP_SRC, "--fpga", FPG_SRC+".x26"]


def main():
    if not os.path.isfile(USBTOOL):
        print("error: edlink.py not found: " + USBTOOL, file=sys.stderr)
        sys.exit(1)

    shutil.copy(FPG_SRC+".rbf", FPG_SRC+".x26")
    
    cmd = [sys.executable, USBTOOL] + ARGS

    result = subprocess.run(cmd)
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
