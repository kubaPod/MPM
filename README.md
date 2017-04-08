# MPM 

Built on top of PacletManager`. 

We are just starting so the functionality is limited and bugs are hiding behind corners. Feedback appreciated!

### What's there?

 - supports custom installation destination (`"Destination"` option) 
 - installs paclets released in .paclet form attached to github releases. (`"Method" ->Automatic`)


### Under development...

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
      , OptionsPattern[{
            PacletInstall,
            "Destination" -> Automatic | _?DirectoryQ,
            "Logger"      -> Print
            "ConfirmRequirements" -> True
        }]
    ]
    
- `"ConfirmRequirements"` informs if installed paclet meets requirements of the Paclet. 
 
  Such exceptions are currently missed by ``PacletManager`Install``. 
  
  `Catch` for `MPMInstall::insreq`
  
- `"Destination"` allows to specify custom installation directory instead of default 
 `$UserBaseDirectory / Paclets / Repository`
   
    
     

### Examples:

    MPMInstall["szhorvat", "MaTeX"]
     
    MPMInstall["kubapod", "MoreStyles"]
     
    MPMInstall["szhorvat", "matex", "v1.6.3", "IgnoreVersion" -> True]
    
## Tips for developers    

### Versioning

 Good to remember that quite often paclets are identified by `x.y.z` tag while associated tag/release is `vx.y.z`.
  
 MPMInstall excepts version matching the source it is refering to. So for GitHub releases it will contain `v`, unless author made it plain `x.y.z`. 
 
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
    
    

     
      

      
      
      

