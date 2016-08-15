[% USE Koha %]
[% USE String %]
[% SET KOHA_VERSION = Koha.Preference('Version') %]
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

[%# Prevent XFS attacks -%]
[% UNLESS popup %]
    <style id="antiClickjack">body{display:none !important;}</style>
[% END %]

<link rel="shortcut icon" href="[% IF ( IntranetFavicon ) %][% IntranetFavicon %][% ELSE %][% interface %]/[% theme %]/img/favicon.ico[% END %]" type="image/x-icon" />

<link rel="stylesheet" type="text/css" href="[% interface %]/lib/jquery/jquery-ui-1.11.4.min_[% KOHA_VERSION %].css" />
<link rel="stylesheet" type="text/css" href="[% interface %]/lib/bootstrap/bootstrap.min_[% KOHA_VERSION %].css" />
<link rel="stylesheet" type="text/css" href="[% interface %]/lib/font-awesome/css/font-awesome.min_[% KOHA_VERSION %].css" />
<link rel="stylesheet" type="text/css" media="print" href="[% interface %]/[% theme %]/css/print_[% KOHA_VERSION %].css" />
[% INCLUDE intranetstylesheet.inc %]
[% IF ( bidi ) %]<link rel="stylesheet" type="text/css" href="[% interface %]/[% theme %]/css/right-to-left_[% KOHA_VERSION %].css" />[% END %]

[% IF ( login ) %]
    <link rel="stylesheet" type="text/css" href="[% interface %]/[% theme %]/css/login_[% KOHA_VERSION %].css" />
[% END %]
[% IF ( IntranetUserCSS ) %]<style type="text/css">[% IntranetUserCSS %]</style>[% END %]

[% INCLUDE js_includes.inc %]
