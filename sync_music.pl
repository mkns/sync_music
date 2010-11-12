#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use File::Copy;
use File::Basename;
use File::Path;

my $source_dir = "/Users/mkns/Music/iTunes/iTunes Media/Music";
my $source_files = {};
my $destination_dir = "/Volumes/Mass memory/Music";
my $destination_files = {};
print "Reading source directory: $source_dir\n";
read_directory( $source_dir, $source_files );
open( FILE, "> source.txt" ) or die $!;
print FILE Dumper( $source_files );
close( FILE );

print "Reading destination directory: $destination_dir\n";
read_directory( $destination_dir, $destination_files );
open( FILE, "> destination.txt" ) or die $!;
print FILE Dumper( $destination_files );
close( FILE );

print "Diffing files\n";
my $diff = diff( $source_files, $destination_files );
open( FILE, "> diff.txt" ) or die $!;
print FILE Dumper( $diff );
close( FILE );

do_delete( $diff->[1] );
do_new( $diff->[0] );
do_update( $diff->[2] );

sleep 2;

sub do_update {
  my ( $files ) = @_;
  do_new( $files );
}

sub do_delete {
  my ( $files ) = @_;
  foreach my $file ( @$files ) {
    print "unlinking $destination_dir/$file\n";
    unlink "$destination_dir/$file";
  }
}

sub do_new {
  my ( $files ) = @_;
  foreach my $file ( @$files ) {
    my ( $name, $path, $suffix ) = fileparse( "$destination_dir/$file" );
    print "mkpath $path\n";
    mkpath( $path );
    print "copying $source_dir/$file to $destination_dir/$file\n";
    copy( "$source_dir/$file", "$destination_dir/$file" );
  }
}

sub diff {
  my ( $source_files, $destination_files ) = @_;
  
  my @new = ();
  foreach my $file ( keys %$source_files ) {
    push @new, $file if !exists( $destination_files->{$file} );
  }
  
  my @deleted = ();
  foreach my $file ( keys %$destination_files ) {
    push @deleted, $file if !exists( $source_files->{$file} );
  }
  
  my @diff = ();
  foreach my $file ( keys %$source_files ) {
    if ( exists( $destination_files->{$file} ) ) {
      push @diff, $file if $source_files->{$file} ne $destination_files->{$file};
    }
  }
  
  @new = sort( @new );
  @deleted = sort( @deleted );
  @diff = sort( @diff );
  
  return [ \@new, \@deleted, \@diff ];
}

sub strip {
  my ( $file ) = @_;
  $file =~ s|$source_dir||;
  $file =~ s|$destination_dir||;
  return $file;
}

sub read_directory {
  my ( $dir, $files ) = @_;

  #print "read_directory() got $dir\n";

  opendir( DIR, $dir ) || die $!;
  my @items = readdir( DIR );
  if ( scalar( @items ) == 2 ) {
    print "Removing empty dir: $dir\n";
    rmdir( $dir ) || warn $!;
  }
  
  foreach my $item ( @items ) {
    next if $item =~ m|^\.|;
    my $item_fullpath = "$dir/$item";
    if ( -d $item_fullpath ) {
      read_directory( $item_fullpath, $files );
    }
    else {
      # must be a file
      #print -s $item_fullpath, "\n";
      $files->{ strip( $item_fullpath ) } = -s $item_fullpath;
    }
  }
}

