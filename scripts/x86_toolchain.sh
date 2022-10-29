#! /bin/bash

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022
#edits by Saiban: 64-bit is default
# Edits by Ben: Implemented getopt for command line

if [ $# -lt 1 ]; then
        echo "Usage:"
        echo ""
        echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
        echo ""
        echo "-v | --verbose                Show some information about steps performed."
        echo "-g | --gdb                    Run gdb command on executable."
        echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
        echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
        echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
        echo "-32| --x86-32                 Compile for 32bit (x86-32) system."
        echo "-o | --output <filename>      Output filename."

        exit 1
fi

GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=True
QEMU=False
BREAK="_start"
RUN=False

# Use getopt to parse command line options. Can be -(short) and/or --(long).
options=$(getopt -o go:v3qrb: --long gdb,output:,verbose,x86-32,qemu,run,break: -- "$@")

# Set positional parameters to the result from getopt.
eval set -- "$options"

# Loop through positional paramters.
while [[ $# -gt 0 ]]; do
        case $1 in
                -g|--gdb)
                        GDB=True
                        shift # past argument
                        ;;
                -o|--output)
                        OUTPUT_FILE="$2"
                        shift # past argument
                        shift # past value
                        ;;
                -v|--verbose)
                        VERBOSE=True
                        shift # past argument
                        ;;
                -3|--x86-32) # Getopt only takes one char for short commands (-32 will no longer work).
                        BITS=False
                        shift # past argument
                        ;;
                -q|--qemu)
                        QEMU=True
                        shift # past argument
                        ;;
                -r|--run)
                        RUN=True
                        shift # past argument
                        ;;
                -b|--break)
                        BREAK="$2"
                        shift # past argument
                        shift # past value
                        ;;
                --)            # Case '--' is always the last arg of getopt args.
                        shift; # past argument 
                        break  # exit the loop 
                        ;;
                *)             # Error case
                        echo "Option $1 is invalid"
                        shift # past argument
                        ;;
        esac
done

# Use original args that were not modified by getopt.
INPUT_FILE="$@"

if [[ ! -f $INPUT_FILE ]]; then
        echo "Specified file does not exist"
        exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then
        OUTPUT_FILE=${INPUT_FILE%.*}
fi

if [ "$VERBOSE" == "True" ]; then
        echo "Arguments being set:"
        echo "  GDB = ${GDB}"
        echo "  RUN = ${RUN}"
        echo "  BREAK = ${BREAK}"
        echo "  QEMU = ${QEMU}"
        echo "  Input File = $INPUT_FILE"
        echo "  Output File = $OUTPUT_FILE"
        echo "  Verbose = $VERBOSE"
        echo "  64 bit mode = $BITS" 
        echo ""

        echo "NASM started..."

fi

if [ "$BITS" == "True" ]; then

        nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then

        nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

if [ "$VERBOSE" == "True" ]; then

        echo "NASM finished"
        echo "Linking with GCC ..."

fi

if [ "$BITS" == "True" ]; then

        gcc -m64 -nostdlib $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then

        gcc -m32 -nostdlib $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi


if [ "$VERBOSE" == "True" ]; then

        echo "Linking finished"

fi

if [ "$QEMU" == "True" ]; then

        echo "Starting QEMU ..."
        echo ""

        if [ "$BITS" == "True" ]; then

                qemu-x86_64 $OUTPUT_FILE && echo ""

        elif [ "$BITS" == "False" ]; then

                qemu-i386 $OUTPUT_FILE && echo ""

        fi

        exit 0

fi

if [ "$GDB" == "True" ]; then

        gdb_params=()
        gdb_params+=(-ex "b ${BREAK}")

        if [ "$RUN" == "True" ]; then

                gdb_params+=(-ex "r")

        fi

        gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
