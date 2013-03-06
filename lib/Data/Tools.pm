##############################################################################
#
#  Data::Tools perl module
#  (c) Vladi Belperchinov-Shabanski "Cade" 2013
#  http://cade.datamax.bg
#  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>
#
#  GPL
#
##############################################################################
package Data::Tools;

use Exporter;
our $VERSION = '1.01';
our @ISA    = qw( Exporter );
our @EXPORT = qw(
              file_save
              file_load
              
              dir_path_make
              dir_path_ensure

              str2hash 
              hash2str
              
              hash_save
              hash_load

              str_url_escape 
              str_url_unescape 
              str_hex 
              str_unhex
              
              url2hash
              
              perl_package_to_file

            );

our %EXPORT_TAGS = (
                   
                   'all' => \@EXPORT,
                   
                   );
            
use strict;

##############################################################################

sub file_load
{
  my $fn = shift; # file name
  
  my $i;
  open( $i, $fn ) or return undef;
  local $/ = undef;
  my $s = <$i>;
  close $i;
  return $s;
}

sub file_save
{
  my $fn = shift; # file name

  my $o;
  open( $o, ">$fn" ) or return 0;
  print $o @_;
  close $o;
  return 1;
}

##############################################################################

sub dir_path_make
{
  my $path = shift;
  my %opt = @_;

  my $mask = $opt{ 'MASK' } || oct('700');
  
  my $abs;

  $path =~ s/\/+$/\//o;
  $abs = '/' if $path =~ s/^\/+//o;

  my @path = split /\/+/, $path;

  $path = $abs;
  for my $p ( @path )
    {
    $path .= "$p/";
    next if -d $path;
    mkdir( $path, $mask ) or return 0;
    }
  return 1;
}

sub dir_path_ensure
{
  my $dir = shift;
  my %opt = @_;

  dir_path_make( $dir, $opt{ 'MASK' } ) unless -d $dir;
  return undef unless -d $dir;
  return $dir;
}

##############################################################################
#   url-style escape & hex escape
##############################################################################

our $URL_ESCAPES_DONE;
our %URL_ESCAPES;
our %URL_ESCAPES_HEX;

sub __url_escapes_init
{
  return if $URL_ESCAPES_DONE;
  for ( 0 .. 255 ) { $URL_ESCAPES{ chr( $_ )     } = sprintf("%%%02X", $_); }
  for ( 0 .. 255 ) { $URL_ESCAPES_HEX{ chr( $_ ) } = sprintf("%02X",   $_); }
  $URL_ESCAPES_DONE = 1;
}

sub str_url_escape
{
  my $text = shift;
  
  $text =~ s/([^ -\$\&-<>-~])/$URL_ESCAPES{$1}/gs;
  return $text;
}

sub str_url_unescape
{
  my $text = shift;
  
  $text =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
  return $text;
}

sub str_hex
{
  my $text = shift;
  
  $text =~ s/(.)/$URL_ESCAPES_HEX{$1}/gs;
  return $text;
}

sub str_unhex
{
  my $text = shift;
  
  $text =~ s/([0-9A-F][0-9A-F])/chr(hex($1))/ge;
  return $text;
}

##############################################################################

sub str2hash
{
  my $str = shift;
  
  my %h;
  for( split( /\n/, $str ) )
    {
    $h{ str_url_unescape( $1 ) } = str_url_unescape( $2 ) if ( /^([^=]+)=(.*)$/ );
    }
  return \%h;
}

sub hash2str
{
  my $hr = shift; # hash reference

  my $s = "";
  while( my ( $k, $v ) = each %$hr )
    {
    $k = str_url_escape( $k );
    $v = str_url_escape( $v );
    $s .= "$k=$v\n";
    }
  return $s;
}

##############################################################################

sub hash_save
{
  my $fn = shift;
  # @_ array of hash references
  my $data;
  $data .= hash2str( $_ ) for @_;
  return save_file( $fn, $data );
}

sub hash_load
{
  my $fn = shift;
  
  return str2hash( load_file( $fn ) );
}

##############################################################################

sub perl_package_to_file
{
  my $s = shift;
  $s =~ s/::/\//g;
  $s .= '.pm';
  return $s;
}

##############################################################################

BEGIN { __url_escapes_init(); }
INIT  { __url_escapes_init(); }

##############################################################################

=pod


=head1 NAME

  Data::Tools provides set of basic functions for data manipulation.

=head1 SYNOPSIS

  use Data::Tools qw( :all );

  my $res  = file_save( $file_name, 'file data here' );
  my $data = file_load( $file_name );
  
  my $res  = dir_path_make( '/path/to/somewhere' ); # create full path with 0700
  my $path = dir_path_ensure( '/path/s/t/h' ); # ensure path exists, check+make
  
  my $escaped   = str_url_escape( $plain_str ); # url-style %XX escaping
  my $plain_str = str_url_unescape( $escaped );
  
  my $hex_str   = str_hex( $plain_str ); # hex-style string escaping
  my $plain_str = str_unhex( $hex_str );
  
  my $hash_str = hash2str( $hash_reference ); # convert hash to string "key=value\n"
  my $hash_reference = str2hash( $hash_str );
  
  # save/load hash in str_url_escaped form to/from a file
  my $res            = hash_save( $file_name, $hash_reference );
  my $hash_reference = hash_load( $file_name );
  
  my $perl_pkg_fn = perl_package_to_file( 'Data::Tools' ); # returns "Data/Tools.pm"

=head1 FUNCTIONS

  (more docs)

=head1 TODO

  (more docs)

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

##############################################################################
1;
