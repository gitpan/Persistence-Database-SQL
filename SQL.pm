# -*-cperl-*-
#
# Persistence::Database::SQL - Object Persistence in SQL Databases.
# Copyright (c) 2000 Ashish Gulhati <hash@netropolis.org>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: SQL.pm,v 1.4 2000/07/29 06:13:37 cvs Exp $

package Persistence::Database::SQL;

use Carp;
use strict;
use vars qw( $VERSION $AUTOLOAD );

( $VERSION ) = '$Revision: 1.4 $' =~ /\s+([\d\.]+)/;

sub new { 
  my ( $class, %args )=@_; my $self=\%args;
  for ('Engine', 'Database', 'Table', 'Template') {
    croak "Must specify $_." unless $self->{$_};
  }
  $self->{Template} = %$self->{Template};
  require "Persistence/Object/$self->{Engine}.pm" 
    or croak "Could not load $self->{Engine} object class.";
  $self->{__DBHandle} = "Persistence::Object::$self->{Engine}"->dbconnect ($self) 
    or croak "Could not initialize database connection."; 
  return bless $self, $class; 
} 

sub search { 
  my ($self, %args) = @_;
  my %rows = "Persistence::Object::$self->{Engine}"->values
    ( __Dope => $self, Key => $args{Key} ); 
  return undef unless %rows;
  map { "Persistence::Object::$self->{Engine}"->load 
	  ( __Dope => $self, __Oid => $_ ) }
    grep { $rows{$_} =~ /$args{Regex}/s } keys %rows;
}

sub dbhandle {
  my $self = shift;
  return $self->{__DBHandle};
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  if ($auto =~ /^(template|table|host|port|username|password)$/) {
    $self->{"\U$auto"} = shift;
    $self->{Template} = %$self->{Template} if $auto eq 'template';
  }
  else {
    croak "Could not AUTOLOAD method $auto.";
  }
}

'True Value'

__END__

=head1 NAME

Persistence::Database::SQL - Object Persistence in SQL Databases. 

=head1 SYNOPSIS

  use Persistence::Database::SQL;

  my $db = new Persistence::Database::SQL
    ( Engine => 'Postgres',
      Database => $database_name, 
      Table => $table_name,
      Template => $template_hashref );

  my (@objects) = $db->search
    ( Key => $key,
      Regex => $regex );

  for $obj (@objects) {
    $db->table('expired'); 
    $obj->commit();
    $db->table($table_name); 
    $obj->expire();
  }

  my $dbhandle = $db->handle();

  my $query = "SELECT oid,* FROM $table_name WHERE $field=$value";
  my $result = $dbhandle->exec ($query);
  while (@row = $result->fetchrow()) {
    my $obj = new Persistence::Object::Postgres
      ( __Dope => $self,
        __Oid => $row[0] );
    $obj->expire();
  }

=head1 DESCRIPTION

This module provides a store of persistent objects using various DBMS
engines. It works in association with a lower level persistent object
implementation, such as Persistence::Object::Postgres. 

Using a template mapping object properties to PostgreSQL class fields,
it is possible to automatically generate DBMS fields out of the object
data, which allows you to use SQL indexing and querying facilities on
your database of persistent objects.

=head1 CONSTRUCTOR 

=over 2

=item B<new()>

Creates a new Database Object.

  my $database = new Persistence::Database::SQL
    ( Engine => 'Postgres',
      Database => $database_name, 
      Table => $table_name,
      Template => $template_hashref );

Takes a hash argument with following possible keys:

B<Engine>

The name of the underlying DBMS engine, for which there must be a
Persistence::Object::Engine class available. Currently, the only
available engine is 'Postgres'. This attribute is required.

B<Database>

The name of the database. A database by this name must exist
previously within the DBMS system in use with sufficient priveleges
for the user. This attribute is required.

B<Table>

The table within the database to use for object storage. This
attribute is required, and can be later changed with the table()
method.

B<Template>

A hashref that maps persistent object key names to database field
names. Only key names that are mapped in the template will be
extracted and stored in separate database fields. The whole object
will always be stored. 

In the degenerate case where you provide an empty template for the
mapping template, only the complete object dump is stored. This
attribute is required, and can be later changed with the template()
method.

B<Host>

The name or IP address of the database server. A default value is
provided by the DBMS-specific object class if this attribute is
omitted.

B<Port>

The port on which the database server can be accessed. A default value
is provided by the DBMS-specific object class if this attribute is
omitted.

B<Username>

The username to use to acccess the database server. A default value,
usually the username of the user running the program, is provided by
the DBMS-specific object class if this attribute is omitted.

B<Password> 

The password for the user. A default value may be provided by the
DBMS-specific object class if this attribute is omitted, though it
would probably be an empty string.

=back 

=head1 OBJECT METHODS

=over 2

=item B<search()> 

Searches the database for objects whose field values match the regular
expression specified.

  $database->search 
    ( Key => $key,
      Regex => $regex ); 

=item B<dbhandle()> 

Returns the handle to the database connection. You could use this to
execute arbitrary SQL queries on the database.

  $handle = $database->dbhandle()

=head1 BUGS

=over 2

=item * 

Error checking needs work. 

=head1 SEE ALSO 

Persistence::Object::Postgres(3), 
Data::Dumper(3), 
Persistence::Object::Simple(3), 
perlobj(1), perlbot(1), perltoot(1).

=head1 AUTHOR

Persistence::Database::SQL is Copyright (c) 2000 Ashish Gulhati
<hash@netropolis.org>. All Rights Reserved.

=head1 ACKNOWLEDGEMENTS

Thanks to Barkha for inspiration, laughs and all 'round good times; to
Vipul for Persistence::Object::Simple, the constant use and abuse of
which resulted in the writing of this module; and of-course, to Larry
Wall, Richard Stallman, and Linus Torvalds.

=head1 LICENSE

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

It would be nice if you would mail your patches to me, and I would
love to hear about projects that make use of this module.

=head1 DISCLAIMER

This is free software. If it breaks, you own both parts.

=cut
