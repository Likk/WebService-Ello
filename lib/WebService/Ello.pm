package WebService::Ello;

=encoding utf8

=head1 NAME

  WebService::Ello - ello.co client for perl.

=head1 SYNOPSIS

  use WebService::Ello;
  my $ello = WebService::Ello->new(
    email    => 'your email', #require if you login
    password => 'your password', #require if you login
  );

  $ello->login(); #if you login
  my $tl = $ello->public_timeline();
  for my $row (@$tl){
    warn YAML::Dump $row;
  }

=head1 DESCRIPTION

  WebService::Ello is scraping library client for perl at ello.co.

=cut

use strict;
use warnings;
use utf8;
use Carp;
use Encode;
use JSON::XS qw/encode_json decode_json/;
use Web::Scraper;
use WWW::Mechanize;
use YAML;

our $VERSION = '0.01';
our $BASE_URL  = 'https://ello.co';

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new ello.co object.

  my $lingr = WebService::Ello->new(
        #optional, but require when you say.
        email =>    q{ello login email},
        password => q{ello password},
  );

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless { %args }, $class;

    $self->{root}     = $BASE_URL;
    $self->{last_req} ||= time;
    $self->{interval} ||= 1;

    $self->mech();
    return $self;
}

=head1 Accessor

=over

=item B<mech>

  WWW::Mechanize object.

=cut

sub mech {
    my $self = shift;
    unless($self->{mech}){
        my $mech = WWW::Mechanize->new(
            agent      => 'Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0',
            cookie_jar => {},
        );
        $mech->stack_depth(10);
        $self->{mech} = $mech;
    }
    return $self->{mech};
}

=item B<interval>

sleeping time per one action by Mech.

=item B<last_request_time>

request time at last;

=item B<last_content>

cache at last decoded content.

=cut

sub interval          { return shift->{interval} ||= 1    }
sub last_request_time { return shift->{last_req} ||= time }

sub last_content {
    my $self = shift;
    my $arg  = shift || '';

    if($arg){
        $self->{last_content} = $arg
    }
    return $self->{last_content} || '';
}

=back

=head1 METHODS

=head2 set_last_request_time

set request time

=cut

sub set_last_request_time { shift->{last_req} = time }


=head2 post

mech post with interval.

=cut

sub post {
    my $self = shift;
    $self->_sleep_interval;
    my $res = $self->mech->post(@_);
    return $self->_content($res);
}

=head2 get

mech get with interval.

=cut

sub get {
    my $self = shift;
    $self->_sleep_interval;
    my $res = $self->mech->get(@_);
    return $self->_content($res);
}

=head2 conf

  url path config

=cut

sub conf {
    my $self = shift;
    unless ($self->{__conf}){
        my $conf = {
            enter   => sprintf("%s/enter", $BASE_URL),
            say     => sprintf("%s/api/v1/posts.json", $BASE_URL),
            friends => sprintf("%s/friends", $BASE_URL),
        };
        $self->{__conf} = $conf;
    }
    return $self->{__conf};
}

=head2 login

  sign in at ello.co

=cut

sub login {
    my $self = shift;

    {
        my $html = $self->get($self->conf->{enter});
        my $authenticity_token;
        if($html =~ m{<meta\scontent="(.*)?"\sname="csrf-token"\s/>}){
            $authenticity_token = $1;
        }
        else {
            Carp::croak('cant get csrf-token. :'. $html);
        }
        my $params = {
            utf8                => '%E2%9C%93',
            authenticity_token  => $authenticity_token,
            'user[email]'       => $self->{email},
            'user[password]'    => $self->{password},
            'user[remember_me]' => 0,
            'user[remember_me]' => 1,
            commit              => 'Enter Ello',
        };
        $self->post($self->conf->{enter}, $params);
    }
}

=head2 get_csrf_token

get csrf-token.

=cut

sub get_csrf_token {
    my $self = shift;

    my $html = $self->get($self->conf->{friends});
    my $authenticity_token;

    if($html =~ m{<meta\scontent="(.*)?"\sname="csrf-token"\s/>}){
        $authenticity_token = $1;
    }
    else{
        Carp::croak('cant get csrf-token');
    }
    return $authenticity_token;
}

=head2 say

post content to ello.co.

=cut

sub say {
    my $self = shift;
    my $args = shift;

    my $json = encode_json([{"kind" => "text", "data" => Encode::decode_utf8($args->{content}),}]);
    my $content = sprintf(qq|----\r\nContent-Disposition: form-data; name="unsanitized_body"\r\n\r\n%s\r\n------\r\n|,$json,);

    $self->rest_post($self->conf->{say}, $content);
}

=head2 rest_post

post to rest API with X-CSRF-Token.

=cut

sub rest_post {
    my ($self, $path, $content) = @_;

    my $csrf_token = $self->get_csrf_token();
    my $headers = { 'X-CSRF-Token' => $csrf_token };

    my $req = HTTP::Request->new(POST => $path );
    $req->content_type("multipart/form-data; boundary=--");
    $req->content($content);
    $req->{_headers} = bless {
        %{ $req->{_headers} },
        %$headers
    }, 'HTTP::Headers';
    $self->mech->request($req);
}

=head1 PRIVATE METHODS.

=over

=item B<_sleep_interval>

アタックにならないように前回のリクエストよりinterval秒待つ。

=cut

sub _sleep_interval {
    my $self = shift;
    my $wait = $self->interval - (time - $self->last_request_time);
    sleep $wait if $wait > 0;
    $self->set_last_request_time();
}

=item b<_content>

decode content with mech.

=cut

sub _content {
  my $self = shift;
  my $res  = shift;
  my $content = $res->decoded_content();
  $self->last_content($content);
  return $content;
}

=back

=cut

1;
__END__

likkradyus E<lt>perl {at} li.que.jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
