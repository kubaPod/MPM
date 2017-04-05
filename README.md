# MPM 

Package supporting advanced installation / management of paclets in Wolfram Mathematica.

We are just starting so the functionality is limited and bugs are hiding behind corners. So feedback appreciated!

**Currently it allows** to automatically install paclets released in .paclet form as assets of github releases.

### Comming soon

 - support for different release types 
 - better documentation
 - packages database


### Installation

    Import[
      "https://raw.githubusercontent.com/kubapod/mpm/master/install.m"
    ]


### Usage

    MPMInstall[
        author     : _String
      , pacletName : _String
      , version    : _String : "latest"
    ]

e.g.:

    MPMInstall["szhorvat", "MaTeX"]
     
    MPMInstall["kubapod", "MoreStyles"]

### Creating compatible releases



- create .paclet

      Needs @ "PacletManager`" (*built-in in Mathematica V10+*)
      PackPaclet @ pacletDirectory
      
- draft a release in your github repository
- attach previously generated .paclet to the release
- done, your paclet can be installed with 

      MPMInstall[you, yourPackage]
      
      
      

