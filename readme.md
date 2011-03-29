# Asset Mover plugin for Movable Type and Melody

The Asset Mover plugin for Movable Type and Melody allows you to move a
file-based asset to a different location. For example, you may want to move
`http://site.com/blog/file.jpg` to `http://site.com/blog/assets/file.jpg`.

# Prerequisites

* Movable Type 4.x or Melody 1.x
* [Melody Compatibility Layer](https://github.com/endevver/mt-plugin-melody-compat/downloads) (for users of Movable Type)

# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

# Use

The Asset Mover can be used at the blog level; visit Manage > Assets to use it. Select the assets you want to move and choose "Move Asset(s)" from the "More actions..." selector then click "Go."

A small window will appear with a text field, giving you a chance to specify the location to move the selected assets to. Specify a path relative to the Blog Site Root. Valid options include:

* `folder`: move the selected assets to a single folder beneath the Blog Site
  Root.
* `folder/hierarchy/for/assets`: move the selected assets to a new location
  several folders deep, again relative to the Blog Site Root.
* `/`: move the selected assets to the Blog Site Root.

Folders will be created as necessary to relocate the selected assets.

Non-file and missing assets will be ignored.

# Caveats

Moving an asset to a different location will cause any references to the old
location to break!

* If you're publishing the moved asset with the `<mt:AssetURL>` tag, for
  example, the fix for this is easy: simply republish.
* If you've inserted the moved asset into an entry (or otherwise "hard-coded")
  the URL, the only solution is to search for the old URL and update it
  accordingly.

# License

This program is distributed under the terms of the GNU General Public License,
version 2.

#Copyright

Copyright 2011, Endevver LLC. All rights reserved.
