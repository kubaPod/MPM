# MPM 

Package supporting advanced installation / management of paclets in Wolfram Mathematica.

We are just starting so the functionality is limited and bugs are hiding behind corners. So feedback appreciated!

Currently it allows to automatically install paclets released in .paclet form as assets of github releases.

### Coming soon

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
    
## Tips for developers    

### Versioning

 Quite often paclets are identified with `x.y.z` tag while associated tag/release is `vx.y.z`. 
 
### Creating compatible releases


- create .paclet

      Needs @ "PacletManager`" (*built-in in Mathematica V10+*)
      PackPaclet @ pacletDirectory
      
- draft a release in your github repository
- attach previously generated .paclet to the release
- done, your paclet can be installed with MPM

  But a potential user needs to have ``MPM` ``, the idea is 
 to have the following script included in your repository README:
  
      Import["https://raw.githubusercontent.com/kubapod/mpm/master/install.m"]
      MPM`MPMInstall["szhorvat", "matex"]
      
  ``MPM` `` is not necessary in this case but if used in one line, the name won't be parsed correctly. So just in case.
    
    

     
      

      
      
      

