/*
 *   This file is part of the TinyCore 6502 MicroKernel, Copyright 2022 Jessie
 *   Oberreuter <joberreu@moselle.com>. As with the Linux Kernel Exception to
 *   the GPL3, programs built to run on the MicroKernel are expected to
 *   include this file. Doing so does not effect their license status.
 * 
 *  Kernel Calls Populate the kernel.arg.* variables appropriately, and then
 *  JSR to one of the velctors below:
 */

#ifndef kernel_api_h
#define kernel_api_h

#include <stdint.h>

struct call {  // Mount at $ff00
    
    long NextEvent;      // Copy the next event into user-space.
    long ReadData;       // Copy primary bulk event data into user-space
    long ReadExt;        // Copy secondary bolk event data into user-space
    long Yield;          // Give unused time to the kernel.
    long Putch;          // deprecated
    long RunBlock;       // 
    long RunNamed;       //
    long reserved;
    
    struct {
        long List;       // Returns a bit-set of available block-accessible devices.
        long GetName;    // Gets the hardware level name of the given block device or media.
        long GetSize;    // Get the number of raw sectors (48 bits) for the given device
        long Read;       // Read a raw sector (48 bit LBA)
        long Write;      // Write a raw sector (48 bit LBA)
        long Format;     // Perform a low-level format if the media support it.
        long Export;     // Update the FileSystem table with the partition table (if present).
    } BlockDevice;
    
    struct {
        long List;       // Returns a bit-set of available logical devices.
        long GetSize;    // Get the size of the partition or logical device in sectors.
        long MkFS;       // Creates a new file-system on the logical device.
        long CheckFS;    // Checks the file-system for errors and corrects them.
        long Mount;      // Mark the file-system as available for File and Directory operations.
        long Unmount;    // Mark the file-system as unavailable for File and Directory operations.
        long ReadBlock;  // Read a partition-local raw sector on an unmounted device.
        long WriteBlock; // Write a partition-local raw sector on an unmounted device.
    } FileSystem;
    
    struct { 
        long Open;       // Open the given file for read, create, or append.
        long Read;       // Request bytes from a file opened for reading.
        long Write;      // Write bytes to a file opened for create or append.
        long Close;      // Close an open file.
        long Rename;     // Rename a closed file.
        long Delete;     // Delete a closed file.
        long Seek;       // Set the next read/write position within an open file.
    } File;
    
    struct {
        long Open;       // Open a directory for reading.
        long Read;       // Read a directory entry; may also return VOLUME and FREE events.
        long Close;      // Close a directory once finished reading.
        long MkDir;      // Create a new directory.
        long RmDir;      // Deletes an existing directory.
    } Directory;
    
    long gate;    
    
    struct {
        long GetIP;      // Get the local IP address.
        long SetIP;      // Set the local IP address.
        long GetDNS;     // Get the configured DNS IP address.
        long SetDNS;     // Set the configured DNS IP address.
        long SendICMP;   // Send an ICMP packet (typically a ping).
        long Match;      // Determine if the current event matches a specific socket.
        
        struct {
            long Init;   // Initialize a 32 byte UDP socket structure.
            long Send;   // Send data via the supplied UDP socket structure.
            long Recv;   // Copy the UDP payload from the event to the user's address space.
        } UDP;
        
        struct {
            long Open;   // Initialize a 256 byte TCP structure for a specified destination.
            long Accept; // Initialize a 256 byte TCP structure from a received SYN packet. 
            long Reject; // Reply to a received TCP packet with a REJECT message.
            long Send;   // Accept some new data and send an ACK along with any unACK'd data.
            long Recv;   // Copy any new TCP bytes into the user's buf and update the socket state.
        } TCP;
    };
    
    struct {
        long Reset;      // Re-init the display.
        long GetSize;    // Returns rows/cols in kernel args.
        long DrawRow;    // Draw text/color buffers left-to-right
        long DrawColumn; // Draw text/color buffers top-to-bottom
    } Display;
    
    struct {
        long GetTime;    // Get the date+time in BCD: YY,YY,MM,DD,HH,MM,SS,cS
        long SetTime;    //
        long GetSysInfo; //
        long SetBPS;     //
    } Config;
};

// Kernel Call Arguments; mount at $f0

struct events_t {
    struct event_t *  event;   // GetNextEvent copies event data here
    char              pending; // Negative count of pending events
};

struct common_t {
    char     dummy[8-sizeof(struct events_t)];
    const void *  ext;
    uint8_t       extlen;
    const void *  buf;
    uint8_t       buflen;
    void *        internal;
};
    
struct fs_mkfs_t {
    uint8_t  drive;
    uint8_t  cookie;
    // label = common.buf; label_len = common.buflen
};
    
struct fs_t {
    union {
        struct fs_mkfs_t  format;
        struct fs_mkfs_t  mkfs;
    };
};

struct fs_open_t {
    uint8_t drive;
    uint8_t cookie;
    uint8_t mode;
    // fname       = common.buf
    // fname_len   = common.buflen
};

enum fs_open_mode {
    READ,
    WRITE,
};

struct fs_read_t {
    uint8_t stream;
    uint8_t buflen;
};

struct fs_write_t {
    uint8_t stream;
    // buf         = common.buf
    // buflen      = common.buflen
};

struct fs_close_t {
    uint8_t stream;
};

struct fs_rename_t {
    uint8_t drive;
    uint8_t cookie;
    // old         = args.buf
    // old_len     = args.buflen
    // new         = args.ext
    // new_len     = args.extlen
};

struct fs_delete_t {
    uint8_t drive;
    uint8_t cookie;
    // fnane       = args.buf
    // fname_len   = args.buflen
};

struct fs_seek_t {
    uint8_t  streak;
    uint8_t  cookie;
    uint32_t position;
};

struct file_t {
    union {
        struct fs_open_t    open;
        struct fs_read_t    read;
        struct fs_write_t   write;
        struct fs_close_t   close;
        struct fs_rename_t  rename;
        struct fs_delete_t  delete;
        struct fs_seek_t    seek;
    };
};

struct dir_open_t {
    uint8_t drive;
    uint8_t cookie;
    // fname       = args.buf
    // fname_len   = args.buflen
};

struct dir_read_t {
    uint8_t stream;
    uint8_t buflen;
};

struct dir_close_t {
    uint8_t stream;
};

struct dir_t {
    union {
        struct dir_open_t   open;
        struct dir_read_t   read;
        struct dir_close_t  close;
        struct dir_open_t   mkdir;
        struct dir_open_t   rmdir;
    };
};

struct display_t {
    uint8_t x; // coordinate or size
    uint8_t y; // coordinate or size
    // text        = args.buf      ; text
    // color       = args.ext      ; color
    // buflen      = args.buflen
};


struct call_args {
    struct events_t events;  // The GetNextEvent dest address is globally reserved.
    union {
        struct common_t   common;
        struct fs_t       fs;
        struct file_t     file;
        struct dir_t      directory;
        struct display_t  display;
     // struct net_t      net;
    };
};




// Events
// The vast majority of kernel operations communicate with userland
// by sending events; the data contained in the various events are
// described following the event list.

struct events {
    uint16_t reserved;
    uint16_t deprecated;
    uint16_t GAME;        // joystick events
    uint16_t DEVICE;      // deprecated
    
    struct {
        uint16_t PRESSED;
        uint16_t RELEASED;
    } key;
    
    struct {
        uint16_t DELTA;
        uint16_t CLICKS;
    } mouse;
    
    struct {
        uint16_t NAME;
        uint16_t SIZE;
        uint16_t DATA;
        uint16_t WROTE;
        uint16_t FORMATTED;
        uint16_t ERROR;
    } block;
    
    struct {
        uint16_t SIZE;
        uint16_t CREATED;
        uint16_t CHECKED;
        uint16_t DATA;
        uint16_t WROTE;
        uint16_t ERROR;
    } fs;
    
    struct {
        uint16_t NOT_FOUND;
        uint16_t OPENED;
        uint16_t DATA;
        uint16_t WROTE;
        uint16_t EOF;
        uint16_t CLOSED;
        uint16_t RENAMED;
        uint16_t DELETED;
        uint16_t ERROR;
        uint16_t SEEK;
    } file;
    
    struct {
        uint16_t OPENED;
        uint16_t VOLUME;
        uint16_t FILE;
        uint16_t FREE;
        uint16_t EOF;
        uint16_t CLOSED;
        uint16_t ERROR;
    } directory;
    
    struct {
        uint16_t TCP;
        uint16_t UDP;
    } net;
    
    struct {
        uint16_t TICK;
    } clock;
};

                 
struct event_key_t {
    uint8_t keyboard;
    uint8_t raw;
    char    ascii;
    char    flags;  // negative for no associated ASCII.
};

struct event_mouse_delta_t {
    char     x;
    char     y;
    char     z;
    uint8_t  buttons;
};

struct event_mouse_clicks_t {
    uint8_t inner;
    uint8_t middle;
    uint8_t outer;
};

struct event_mouse_t {
    union {
        struct event_mouse_delta_t  delta;
        struct event_mouse_clicks_t clicks;
    };
};

struct event_fs_data_t {
    uint8_t requested;    // Requested number of bytes to read
    uint8_t delivered;    // Number of bytes actually read
};

struct event_fs_wrote_t {
    uint8_t requested;    // Requested number of bytes to write
    uint8_t delivered;    // Number of bytes actually written
};

struct event_file_t {
    uint8_t stream;
    uint8_t cookie;
    union {
        struct    event_fs_data_t   data;
        struct    event_fs_wrote_t  wrote;
    };
};

struct event_dir_vol_t { // ext contains disk id
    uint8_t len;    // Length of volname (in buf)
    uint8_t flags;  // block size, text encoding
};

struct event_dir_file_t { // ext contains byte count and modified date
    uint8_t len;    // Length of name (in buf)
    uint8_t flags;  // block size, text encoding
};

struct event_dir_free_t {  // ext contains the block count &c
    uint8_t flags;  // block size, text encoding
};

struct dir_ext_t {  // Extended information; more to follow.
    uint32_t free;  // Actually, 48 bits, but you'll prolly never hit it.
};

struct event_dir_t {
    uint8_t stream;
    uint8_t cookie;
    union {
        struct event_dir_vol_t  volume;
        struct event_dir_file_t file;
        struct event_dir_free_t free;
    };
};

struct event_t {
    uint8_t type;
    uint8_t buf;    // kernel's buf page ID
    uint8_t ext;    // kernel's ext page ID
    union {
        struct event_key_t    key;
        struct event_mouse_t  mouse;
        struct event_file_t   file;
        struct event_dir_t    directory;
    };
};
#endif
