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
use strict;
use Exporter;
use Carp;
use Digest::Whirlpool;
use Digest::MD5;
use Digest::SHA1;

our $VERSION = '1.06';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

              file_save
              file_load
              
              dir_path_make
              dir_path_ensure

              str2hash 
              hash2str

              url2hash
              
              hash_uc
              hash_lc
              hash_uc_ipl
              hash_lc_ipl
              
              hash_save
              hash_load
              
              hash_validate

              str_url_escape 
              str_url_unescape 
              
              str_html_escape 
              str_html_unescape 
              
              str_hex 
              str_unhex
              
              perl_package_to_file

              wp_hex
              md5_hex
              sha1_hex

            );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );
            

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

my %HTML_ESCAPES = (
                   '>' => '&gt;',
                   '<' => '&lt;',
                   "'" => '&rsquo;',
                   "`" => '&lsquo;',
                   );

sub str_html_escape
{
  my $text = shift;

  $text =~ s/([<>])/$HTML_ESCAPES{ $1 }/ge;
  
  return $text;
}

sub str_html_unescape
{
  my $text = shift;

  confess "still not implemented";
  
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

sub url2hash
{
  my $str = shift;
  my %hash;
  for( split( /&/, $str ) )
    {
    $hash{ uc str_url_unescape( $1 ) } = str_url_unescape( $2 ) if ( /^([^=]+)=(.*)$/ );
    }
  return \%hash;
}

##############################################################################

sub __hash_ulc
{
  my $hr  = shift;
  my $uc  = shift;
  my $ipl = shift;
  
  my $nr = $ipl ? $hr : {};
  while( my ( $k, $v ) = each %$hr )
    {
    my $old_k = $k;
    $k = $uc ? uc( $k ) : lc( $k );
    $nr->{ $k } = $v;
    delete $nr->{ $old_k } if $ipl and $k ne $old_k;
    }
  return $nr;  
}

sub hash_uc
{
  return __hash_ulc( shift(), 1, 0 );
}

sub hash_lc
{
  return __hash_ulc( shift(), 0, 0 );
}

sub hash_uc_ipl
{
  return __hash_ulc( shift(), 1, 1 );
}

sub hash_lc_ipl
{
  return __hash_ulc( shift(), 0, 1 );
}

##############################################################################

sub hash_save
{
  my $fn = shift;
  # @_ array of hash references
  my $data;
  $data .= hash2str( $_ ) for @_;
  return file_save( $fn, $data );
}

sub hash_load
{
  my $fn = shift;
  
  return str2hash( file_load( $fn ) );
}

##############################################################################

sub hash_validate
{
  my $hr = shift; # hashref to validate
  my $vr = shift; # hashref with expectations
  
  my @err; # invalid keys
  
  while( my ( $k, $v ) = each %$hr )
    {
    if( ! exists $vr->{ $k } )
      {
      push @err, $k;
      next;
      }
    
    my $vv = $vr->{ $k };
    
    if( ref( $v ) eq 'HASH' )
      {
      my @e = hash_validate( $v, $vv );
      for my $e ( @e )
        {
        push @err, "$k/$e";
        }
      }
    elsif( $vv =~ /^\s*(int|real|float)\s*(\(\s*(\d+)\s*,\s*(\d+)\s*\))?\s*$/i )
      {
      my $y = uc $1;
      my $f = $3;
      my $t = $4;

      $v =~ s/[\s'`]+//g;
      
      my $re;
      $re = qr/^[-+]?\d+$/ if $y eq 'INT';
      $re = qr/^[-+]?\d+(\.\d*)?$/ if $y eq 'REAL' or $y eq 'FLOAT';

      #print STDERR Data::Dumper::Dumper( '=int=real='x5, $k, $v, $vv, $re  );

      if( $v =~ /$re/ )
        {
        push @err, $k if $f ne '' and $v < $f;
        push @err, $k if $t ne '' and $v > $t;
        }
      else
        {
        push @err, $k;
        }  
      }
    elsif( $vv =~ /^\s*RE(I)?:\s*(.*?)\s*$/i )
      {
      my $ic = $1; # ignore case
      my $re = $ic ? qr/$2/i : qr/$2/;
      # print Data::Dumper::Dumper( '=re=rei='x5, $k, $v, $vv, $re, $ic );
      push @err, $k unless $v =~ /$re/;
      }  
    elsif( $vv =~ /^\s*(-d|dir|directory)\s*$/i )
      {
      push @err, $k unless -d $v;
      }  
    elsif( $vv =~ /^\s*(-f|file)\s*$/i )
      {
      push @err, $k unless -f $v;
      }  
    }
    
  return wantarray() ? sort( @err ) : @err > 0 ? 0 : 1;
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

sub wp_hex
{
  my $s = shift;

  my $wp = Digest->new( 'Whirlpool' );
  $wp->add( $s );
  my $hex = $wp->hexdigest();

  return $hex;
}

sub md5_hex
{
  my $s = shift;

  my $hex = Digest::MD5::md5_hex( $s );

  return $hex;
}

sub sha1_hex
{
  my $s = shift;

  my $hex = Digest::SHA1::sha1_hex( $s );

  return $hex;
}

##############################################################################

BEGIN { __url_escapes_init(); }
INIT  { __url_escapes_init(); }

##############################################################################

=pod


=head1 NAME

  Data::Tools provides set of basic functions for data manipulation.

=head1 SYNOPSIS

  use Data::Tools qw( :all );  # import all functions
  use Data::Tools;             # the same as :all :) 
  use Data::Tools qw( :none ); # do not import anything, use full package names

  # --------------------------------------------------------------------------

  my $res     = file_save( $file_name, 'file content here' );
  my $content = file_load( $file_name );

  # --------------------------------------------------------------------------
  
  my $res  = dir_path_make( '/path/to/somewhere' ); # create full path with 0700
  my $res  = dir_path_make( '/new/path', MASK => 0755 ); # ...with mask 0755
  my $path = dir_path_ensure( '/path/s/t/h' ); # ensure path exists, check+make

  # --------------------------------------------------------------------------
  
  my $hash_str = hash2str( $hash_ref ); # convert hash to string "key=value\n"
  my $hash_ref = str2hash( $hash_str ); # convert str "key-value\n" to hash
  
  my $hash_ref = url2hash( 'key1=val1&key2=val2&testing=tralala);
  # $hash_ref will be { key1 => 'val1', key2 => 'val2', testing => 'tralala' }

  my $hash_ref_with_upper_case_keys = hash_uc( $hash_ref_with_lower_case_keys );
  my $hash_ref_with_lower_case_keys = hash_lc( $hash_ref_with_upper_case_keys );

  hash_uc_ipl( $hash_ref_to_be_converted_to_upper_case_keys );
  hash_lc_ipl( $hash_ref_to_be_converted_to_lower_case_keys );
  
  # save/load hash in str_url_escaped form to/from a file
  my $res      = hash_save( $file_name, $hash_ref );
  my $hash_ref = hash_load( $file_name );

  # validate (nested) hash by example
  
  # validation example nested hash
  my $validate_hr = {
                    A => 'INT',
                    B => 'INT(-5,10)',
                    C => 'REAL',
                    D => {
                         E => 'RE:\d+[a-f]*',  # regexp match
                         F => 'REI:\d+[a-f]*', # case insensitive regexp match
                         },
                    DIR1  => '-d',   # must be existing directory
                    DIR2  => 'dir',  # must be existing directory
                    FILE1 => '-f',   # must be existing file  
                    FILE2 => 'file', # must be existing file  
                    };
  # actual nested hash to be verified if looks like the example
  my $data_hr     = {
                    A => '123',
                    B =>  '-1',
                    C =>  '1 234 567.89',
                    D => {
                         E => '123abc',
                         F => '456FFF',
                         },
                    }               
  
  my @invalid_keys = hash_validate( $data_hr, $validate_hr );
  print "YES!" if hash_validate( $data_hr, $validate_hr );

  # --------------------------------------------------------------------------
  
  my $escaped   = str_url_escape( $plain_str ); # URL-style %XX escaping
  my $plain_str = str_url_unescape( $escaped );

  my $escaped   = str_html_escape( $plain_str ); # HTML-style &name; escaping
  my $plain_str = str_html_unescape( $escaped );
  
  my $hex_str   = str_hex( $plain_str ); # HEX-style XX string escaping
  my $plain_str = str_unhex( $hex_str );

  # --------------------------------------------------------------------------
  
  # converts perl package names to file names, f.e: returns "Data/Tools.pm"
  my $perl_pkg_fn = perl_package_to_file( 'Data::Tools' );

  # --------------------------------------------------------------------------

  # calculating hex digests
  my $whirlpool_hex = wp_hex( $data );
  my $sha1_hex      = sha1_hex( $data );
  my $md5_hex       = md5_hex( $data );

=head1 FUNCTIONS

=head2 hash_validate( $data_hr, $validate_hr );

Return value can be either scalar or array context. In scalar context return
value is true (1) or false (0). In array context it returns list of the invalid
keys (possibly key paths like 'KEY1/KEY2/KEY3'):

  # array context
  my @invalid_keys = hash_validate( $data_hr, $validate_hr );
  
  # scalar context
  print "YES!" if hash_validate( $data_hr, $validate_hr );

=head1 TODO

  (more docs)

=head1 REQUIRED MODULES

Data::Tools is designed to be simple, compact and self sufficient. 
However it uses some 3rd party modules:

  * Digest::Whirlpool
  * Digest::MD5
  * Digest::SHA1

=head1 SEE ALSO

For more complex cases of nested hash validation, 
check Data::Validate::Struct module by Thomas Linden, cheers :)

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

##############################################################################
1;
