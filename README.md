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

- general method
    
      MPMInstall[
        author     : _String
      , pacletName : _String
      , version    : _String : "latest"  
      , OptionsPattern[]    
      ]
      
- from url
    
      MPMInstall[
        url : _String /; StringMatchQ[url, "http"|"ftp"~~__~~".paclet"]
      , OptionsPattern[]      
      ]      

- from file
    
       MPMInstall[
        path : _String ? FileExistsQ /; StringEndsQ[pacletPath, ".paclet"]
      , OptionsPattern[]      
      ]      
    
### Options    
    
`MPMInstall` takes all `Options[PacletInstall]` and passes them to `PacletInstall` at the end.

Additionally:

- `"Destination"` allows to specify custom installation directory instead of default 
 `$UserBaseDirectory / Paclets / Repository`

- `"ConfirmRequirements"` informs if an installed paclet meets requirements of the Paclet. 
 
  Such exceptions are missed by ``PacletManager`Install`` before MMA V11.2. 
  
  `Catch` for `MPMInstall::insreq`

- `"Logger"` by default `Print` informs about the state of installation.

- `"AllowPrereleases"` by default `False` specifies whether pre-releases should be taken into account.
               
    
  

   
    
     

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
 to have an analogous script included in your repository README:
  
      Import["https://raw.githubusercontent.com/kubapod/mpm/master/install.m"]
      MPM`MPMInstall["kubapod", "morestyles"]
      
  ``MPM` `` is not necessary in this case but if used in one line, the name won't be parsed correctly. So just in case.
    
    

     
      

      
      
      

