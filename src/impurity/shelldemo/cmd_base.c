/*
 * Copyright (c) 2004-2005 vlad902 <vlad902 [at] gmail.com>
 * This file is part of the Metasploit Framework.
 * $Revision$
 */

#include <sys/types.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>

#include "cmd.h"


void cmd_help(int argc, char * argv[])
{
/* XXX: Better descriptions. */
	printf(	"Available commands:\n"
		"    help                            Show this help screen\n"
		"    fork                            Fork off another shelldemo process\n"
		"    exec <cmd>                      Execute <cmd>\n"
		"    forkexec <cmd>                  Fork, close stdin/stdout/stderr and execute <cmd>\n"
		"    quit                            Exit the shell\n"

		"\n"
		"    open <path>                     Open a file and return the file descriptor\n"
		"    lseek <fd> <offset> <whence>    Reposition <fd>\n"
		"    read <fd> [bytes]               Read <bytes> from file descriptor\n"
		"    write <fd> [bytes]              Write [bytes] (or until \"EOF\") to <fd>\n"
		"    close <fd>                      Close specified file descriptor\n"
		"    dup <old_fd>                    Duplicate <old_fd> and return new reference\n"
		"    dup2 <old_fd> <new_fd>          Duplicate <old_fd> to <new_fd>\n"

		"\n"
		"    ls [dir]                        List contents of dir (default: .)\n"
		"    getcwd                          Get current working directory\n"
		"    chmod <permission> <path>       Change <path> permissions to <permission>\n"
		"    chown <user> <path>             Change <path> owner to <user>\n"
		"    chgrp <group> <path>            Change <path> group to <group>\n"
		"    chdir <path>                    Change working directory to <path>\n"
		"    mkdir <path> [permission]       Create <path> directory with [permission] (default: 755)\n"
		"    rmdir <path>                    Remove <path> directory\n"
		"    rename <old_file> <new_file>    Rename <old_file> to <new_file>\n"
		"    unlink <path>                   Remove <path> file\n"
		"    chroot <path>                   Change root directory to <path>\n"
/* XXX: Proper spelling of reference? Symbolically? */
		"    link <file> <reference>         Hard link <reference> to <file>\n"
		"    symlink <file> <reference>      Symbolically link <reference> to <file>\n"

		"\n"
		"    getid                           Print information about [e][ug]id\n"
		"    setuid <uid>                    Set UID to <uid>\n"
		"    setgid <gid>                    Set GID to <gid>\n"

		"\n"
		"    kill <pid> [signal]             Send <pid> [signal] (default: 9)\n"
		"    getpid                          Print current process ID\n"
		"    getppid                         Print parent process ID\n"

		"\n"
		"    time                            Display the current system time\n"
		"    uname                           Get kernel information\n"
		"    hostname [name]                 Print (or set) the hostname\n"
		"    reboot                          Reboot the computer\n"
		"    shutdown                        Shutdown the computer\n"
		"    halt                            Halt the computer\n"

		"\n"
		"    lsfd                            Show information about open file descriptors\n"

		"\n"
		"Warning! Before using any of the following you are recommended to fork for your own safety!\n"
		"    fchdir_breakchroot <temp_dir>   Use <temp_dir> to attempt to break out of chroot\n");
}


/* XXX: sig_chld stuff is dirty, get rid of it */

void cmd_fork(int argc, char * argv[])
{
	pid_t fork_pid;

	signal(SIGCHLD, &sig_chld_ignore);
	if((fork_pid = fork()) != 0)
	{
		while(waitpid(fork_pid, NULL, WNOHANG) <= 0)
			usleep(200);
	}
	signal(SIGCHLD, &sig_chld_waitpid);
}

void cmd_exec(char * string)
{
	execl("/bin/sh", "sh", "-c", string, NULL);
	perror("execl");
}

void cmd_forkexec(char * string)
{
	system(string);
}

void cmd_quit(int argc, char * argv[])
{
	exit(0);
}
