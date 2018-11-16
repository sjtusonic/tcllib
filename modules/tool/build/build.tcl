set srcdir [file dirname [file normalize [file join [pwd] [info script]]]]
set moddir [file dirname $srcdir]

set version 0.8.1
set module [file tail $moddir]

set fout [open [file join $moddir ${module}.tcl] w]
dict set map %module% $module
dict set map %version% $version

puts $fout [string map $map {###
# Amalgamated package for %module%
# Do not edit directly, tweak the source in src/ and rerun
# build.tcl
###
package provide %module% %version%
namespace eval ::%module% {}
}]
if {$module ne "tool"} {
  puts $fout [string map $map {::tool::module push %module%}]
}

# Track what files we have included so far
set loaded {}
lappend loaded build.tcl

# These files must be loaded in a particular order
foreach file {
  core.tcl
  uuid.tcl
  ensemble.tcl
  metaclass.tcl
  option.tcl
  event.tcl
  pipeline.tcl
} {
  lappend loaded $file
  set fin [open [file join $srcdir $file] r]
  puts $fout "###\n# START: [file tail $file]\n###"
  puts $fout [read $fin]
  close $fin
  puts $fout "###\n# END: [file tail $file]\n###"
}
# These files can be loaded in any order
foreach file [lsort -dictionary [glob [file join $srcdir *.tcl]]] {
  if {[file tail $file] in $loaded} continue
  lappend loaded $file
  set fin [open [file join $srcdir $file] r]
  puts $fout "###\n# START: [file tail $file]\n###"
  puts $fout [read $fin]
  close $fin
  puts $fout "###\n# END: [file tail $file]\n###"
}

# Provide some cleanup and our final package provide
puts $fout [string map $map {
namespace eval ::%module% {
  namespace export *
}
}]
close $fout

###
# Build our pkgIndex.tcl file
###
set fout [open [file join $moddir pkgIndex.tcl] w]
puts $fout [string map $map {# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded %module% %version% [list source [file join $dir %module%.tcl]]
}]
close $fout
