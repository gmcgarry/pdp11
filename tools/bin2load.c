/*
 * © 2020 Aaron Taylor <ataylor at subgeniuskitty dot com>
 * See LICENSE.txt file for copyright and license details.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>

#define VERSION 2 

void
print_usage(char ** argv)
{
    printf( "bin2load v%d (www.subgeniuskitty.com)\n"
            "Usage: %s -i <file> -o <file> [-a <address>]\n"
            "  -i <file>    Raw binary file to be written to tape.\n"
            "               For example, output from 'pdp11-aout-objdump' (see README.md).\n"
            "  -o <file>    Output file created by bin2load containing tape image for use with SIMH.\n"
            "  -a <address> (optional) Address on PDP-11 at which to load tape contents.\n"
            , VERSION, argv[0]
    );
}

int
main(int argc, char ** argv)
{
    int c;
    FILE * src = NULL;
    FILE * dst = NULL;
    uint16_t address = 01000; /* Default address to load tape contents in RAM. */

    while ((c = getopt(argc, argv, "i:o:a:h")) != -1) {
        switch (c) {
            case 'i':
                if ((src = fopen(optarg, "r")) == NULL ) {
                    fprintf(stderr, "ERROR: %s: %s\n", optarg, strerror(errno));
                }
                break;
            case 'o':
                if ((dst = fopen(optarg, "w+")) == NULL ) {
                    fprintf(stderr, "ERROR: %s: %s\n", optarg, strerror(errno));
                }
                break;
            case 'a':
                address = (uint16_t) strtol(optarg, NULL, 0);
                break;
            case 'h':
                print_usage(argv);
                exit(EXIT_FAILURE);
                break;
            default:
                break;
        }
    }

    if (src == NULL || dst == NULL) {
        print_usage(argv);
        exit(EXIT_FAILURE);
    }

    printf("Paper tape will load at address 0%o.\n", address);

    /*
     * SIMH Binary Loader Format
     *
     * Loader format consists of blocks, optionally preceded, separated, and
     * followed by zeroes. Each block consists of the following entries. Note
     * that all entries are one byte.
     *
     *     0001
     *     0000
     *     Low byte of block length (data byte count + 6 for header, excludes checksum)
     *     High byte of block length
     *     Low byte of load address
     *     High byte of load address
     *     Data byte 0
     *       ...
     *     Data byte N
     *     Checksum
     *
     * The 8-bit checksum for a block is the twos-complement of the lower eight
     * sum bits for all six header bytes and all data bytes.
     *
     * If the block length is exactly six bytes (i.e. only header, no data),
     * then the block marks the end-of-tape. The checksum should be zero.  If
     * the load address of this final block is not 000001, then it is used as
     * the starting PC.
     */

    uint32_t checksum = 0;
    uint32_t size = 6;
    uint8_t data;

    /* Write header for data block. */
    for (int i = 0; i < size; i++) {
        switch (i) {
            case 0: data = 0001;                  break;
            case 1: data = 0000;                  break;
            case 2: data = 0000;                  break; /* Size will be populated later */
            case 3: data = 0000;                  break; /* Size will be populated later */
            case 4: data = address & 0xff;        break;
            case 5: data = (address >> 8) & 0xff; break;
        }
        if (!fwrite(&data, 1, 1, dst)) {
            fprintf(stderr, "ERROR: Failed to write block header.\n");
            exit(EXIT_FAILURE);
        }
        checksum += data;
    }

    /* Write contents of data block. */
    while (1) {
        if (fread(&data, 1, 1, src)) {
            if (!fwrite(&data, 1, 1, dst)) {
                fprintf(stderr, "ERROR: Failed to write block data.\n");
                exit(EXIT_FAILURE);
            }
            size++;
            checksum += data;
        } else {
            break;
        }
    }
    fclose(src);

    /* Now that block size is known, update block header. */
    if (fseek(dst, 2, SEEK_SET)) {
        fprintf(stderr, "ERROR: Failed seek back to header of data block.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0: data = size & 0xff;        break;
            case 1: data = (size >> 8) & 0xff; break;
        }
        if (!fwrite(&data, 1, 1, dst)) {
            fprintf(stderr, "ERROR: Failed to write block size into header.\n");
            exit(EXIT_FAILURE);
        }
        checksum += data; // Header is included in checksum.
    }
    if (fseek(dst, 0, SEEK_END)) {
        fprintf(stderr, "ERROR: Failed seek to end of data block.\n");
        exit(EXIT_FAILURE);
    }

    /* Write checksum for data block. */
    checksum = (~checksum) + 1;
    data = checksum & 0xff;
    if (!fwrite(&data, 1, 1, dst)) {
        fprintf(stderr, "ERROR: Failed to write checksum.\n");
        exit(EXIT_FAILURE);
    }

    /* Write empty block to indicate end-of-tape. */
    checksum = 0;
    for (int i = 0; i < 7; i++) {
        switch (i) {
            case 0: data = 0001;                  break;
            case 1: data = 0000;                  break;
            case 2: data = 0006;                  break;
            case 3: data = 0000;                  break;
            case 4: data = address & 0xff;        break;
            case 5: data = (address >> 8) & 0xff; break;
            case 6: data = (~checksum) + 1;       break;
        }
        if (!fwrite(&data, 1, 1, dst)) {
            fprintf(stderr, "ERROR: Failed to write end-of-tape block.\n");
            exit(EXIT_FAILURE);
        }
        checksum += data;
    }
    fclose(dst);
}
