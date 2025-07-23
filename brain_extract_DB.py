#!/usr/bin/env python3
__author__ = "Monica Keith"
__status__ = "Production"
__purpose__ = "Perform brain extraction"

import sys
import os
import mysql.connector
import subprocess

def connect():
    fout = open("db_info.txt",'r')
    username = fout.readline().replace("\n","")
    password = fout.readline().replace("\n","")
    hostdir = fout.readline().replace("\n","")
    db_name = fout.readline().replace("\n","")
    fout.close()
    cnx = mysql.connector.connect(user=username, password=password, host=hostdir, database=db_name)
    return cnx

def getIncluded(cursor,sess):
    included = []
    for ddir in ["75_AP","75_PA","76_AP","76_PA"]:
        cursor.execute(f"select {ddir} from sessions where sess='{sess}'")
        val = cursor.fetchone()[0]
        if val==1:
            included+=[ddir]
    return included

def getSbjID(cursor,sess):
    cursor.execute(f"select sbjID from sessions where sess='{sess}'")
    return cursor.fetchone()[0]

def main():
    if len(sys.argv)!=3:
        sys.exit("ERROR: wrong number of arguments")
    sess = sys.argv[1]
    sessdir = sys.argv[2]

    cnx = connect()
    cursor = cnx.cursor()
    sbj = getSbjID(cursor,sess)

    procs = []
    for diffdir in getIncluded(cursor,sess):
        prefix = f"{sessdir}/{sbj}_3T_DWI_dir{diffdir}"
        if not os.path.isfile(f"{prefix}.nii.gz"):
            sys.exit(f"ERROR: {prefix}.nii.gz not found")

        cmd = f"echo 'Masking {diffdir}' && "\
        f"fslroi {prefix} {prefix}_b0 0 -1 0 -1 0 -1 0 1 && "\
        f"bet {prefix}_b0 {prefix}_bet -f 0.1 -g 0 -n -m && "\
        f"echo 'done {diffdir}'"
        p = subprocess.Popen(cmd,shell=True)
        procs+=[p]

    cursor.close()
    cnx.close()

    exit_codes = [p.wait() for p in procs]
    print(exit_codes)

if __name__ == "__main__":
        main()
