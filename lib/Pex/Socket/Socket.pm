#!/usr/bin/perl
###############

##
#         Name: Socket.pm
#       Author: spoonm <ninjatools [at] hush.com>
#       Author: H D Moore <hdm [at] metasploit.com>
#      Version: $Revision$
#      License:
#
#      This file is part of the Metasploit Exploit Framework
#      and is subject to the same licenses and copyrights as
#      the rest of this package.
#
##

package Pex::Socket::Socket;
use strict;
use IO::Socket::INET;
use IO::Select;

sub Socket {
  my $self = shift;
  $self->{'Socket'} = shift if(@_);
  return($self->{'Socket'});
}
sub PeerAddr {
  my $self = shift;
  $self->{'PeerAddr'} = shift if(@_);
  return($self->{'PeerAddr'});
}
sub PeerPort {
  my $self = shift;
  $self->{'PeerPort'} = shift if(@_);
  return($self->{'PeerPort'});
}
sub LocalPort {
  my $self = shift;
  $self->{'LocalPort'} = shift if(@_);
  return($self->{'LocalPort'});
}
sub LocalAddr {
  my $self = shift;
  $self->{'LocalAddr'} = shift if(@_);
  return($self->{'LocalAddr'});
}


sub Timeout {
  my $self = shift;
  $self->{'Timeout'} = shift if(@_);
  return($self->{'Timeout'});
}
sub RecvTimeout {
  my $self = shift;
  $self->{'RecvTimeout'} = shift if(@_);
  return($self->{'RecvTimeout'});
}
sub RecvLoopTimeout {
  my $self = shift;
  $self->{'RecvLoopTimeout'} = shift if(@_);
  return($self->{'RecvLoopTimeout'});
}

sub SetOptions {
  my $self = shift;
  my $hash = shift;

  my @options = ('Timeout', 'RecvTimeout', 'RecvLoopTimeout', 'PeerAddr', 'PeerPort', 'LocalPeerPort');
  foreach my $option (@options) {
    $self->$option($hash->{$option}) if(exists($hash->{$option}));
  }
}



sub SetError {
  my $self = shift;
  my $error = shift;
  $self->{'Error'} = $error;
}

sub GetError {
  my $self = shift;
  return($self->{'Error'});
}

sub IsError {
  my $self = shift;
  return(defined($self->GetError));
}
sub ClearError {
  my $self = shift;
  $self->SetError(undef);
}


sub Buffer {
  my $self = shift;
  $self->{'Buffer'} = shift if(@_);
  return($self->{'Buffer'});
}

sub AddBuffer {
  my $self = shift;
  my $buffer = shift;
  $self->{'Buffer'} .= $buffer;
}

sub GetBuffer {
  my $self = shift;
  my $size = @_ ? shift : return($self->Buffer);

  return(substr($self->Buffer, 0, $size));
}

sub RemoveBuffer {
  my $self = shift;
  my $size = @_ ? shift : 999999999;
  return('') if(! defined($self->{'Buffer'}) || ! length($self->{'Buffer'}));
  return(substr($self->{'Buffer'}, 0, $size, ''));
}

sub SocketError {
  my $self = shift;
  my $ignoreConn = shift;

  my $reason;
  if(!$self->Socket) {
    $reason = 'no socket';
  }
  elsif(!$ignoreConn && !$self->Socket->connected) {
    $reason = 'not connected';
  }

  if($reason) {
    $self->SetError('Invalid socket: ' . $reason);
    return(1);
  }

  return(0);
}

sub Close {
  my $self = shift;
  if($self->Socket) {
    $self->Socket->shutdown(2);
    $self->Socket->close;
  }
}

sub Send {
  my $self = shift;
  my $data = shift;
  my $delay = @_ ? shift : .1;

  return if($self->GetError);

  my $failed = 5;
  while(length($data)) {
    return if($self->SocketError);

    my $sent = $self->_DoSend($data);

    last if($sent == length($data));

    $data = substr($data, $sent);
    if(!--$failed) {
      $self->SetError("Send retry limit reached.");
      return(0);
    }
    select(undef, undef, undef, $delay); # sleep
  }
  return(1);
}

sub _DoSend {
  my $self = shift;
  return if(!$self->Socket->connected);
  return($self->Socket->send(@_));
}


sub Recv {
  my $self = shift;
  my $length = shift;
  my $timeout = @_ ? shift : $self->RecvTimeout;

  return if($self->GetError);
  return if($self->SocketError(1));

  my $data;
  if($length == -1) {
    $data = $self->RemoveBuffer . $self->_RecvGobble($timeout);
  }
  else {
    my $buffer = $self->RemoveBuffer($length);
    $data = $buffer . $self->_RecvLength($length - length($buffer));
  }

  $self->ClearError if(length($data));
  return($data);
}
  

# Special case -1 lengths, we will wait up to timeout to get
# any data, and then we just read as much as we can, and return.
sub _RecvGobble {
  my $self = shift;
  my $timeout = shift;

  my $selector = IO::Select->new($self->Socket);
  my $data;

  my ($ready) = $selector->can_read($timeout);

  if(!$ready) {
    # $self->SetError("Timeout $timeout reached."); # there could be data from buffer anyway
    return($data);
  }

  my $timeoutLoop = $self->RecvLoopTimeout;
  while(1) {
    my ($ready) = $selector->can_read($timeoutLoop);
    last if(!$ready);

    my $tempData = $self->_DoRecv(4096, 1);

    if(!length($tempData)) {
      last;
    }
    $data .= $tempData;   
  }
  return($data);
}

sub _RecvLength {
  my $self = shift;
  my $length = shift;
  my $timeout = shift;

  my $selector = IO::Select->new($self->Socket);
  my $data;

  while($length) {
    my ($ready) = $selector->can_read($timeout);

    if(!$ready) {
      # $self->SetError("Timeout $timeout reached.");
      $self->SetError("Socket disconnected.") if(!$self->Socket->connected);
      return($data);
    }

    # We gotz data y0
    my $tempData = $self->_DoRecv($length, $timeout ? 5 : 0);

    if(!length($tempData)) {
      return($data);
    }

    $data .= $tempData;
    if(length($tempData) > $length) {
      $self->AddBuffer(substr($tempData, $length));
      $tempData = substr($tempData, 0, $length);
    }
    $length -= length($tempData);
  }

  return($data);
}

sub _DoRecv {
  my $self = shift;
  my $length = shift;
  my $trys = shift;
  my $data;
  $self->Socket->recv($data, $length);
  $self->SetError('Socket disconnected') if(!length($data));
  return($data);
}

1;