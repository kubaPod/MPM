(* ::Package:: *)

System`MPM::insv = "MPM only supports Mathematica `` or later.";

If[
    $VersionNumber < #
  , Message[System`MPM::insv, #]
  ; Abort[]
]&[10.4];

ClearAll["MPM`*"];
ClearAll["MPM`*`*"];


(* ::Section:: *)
(*Begin*)


BeginPackage["MPM`"];

  Needs @ "PacletManager`";

  MPMInstall;

  WithPacletRepository;

Begin["`Private`"];


(* ::Section:: *)
(*Content*)


(* ::Subsubsection:: *)
(*settings*)


(*TODO: check whether the paclet can be found after it is installed.
  If it is not, inform user that it probably doesn't meet requirements*)
  
  $DefaultLogger = Print;
  dPrint = If[TrueQ @ System`Private`$mpmDebug, (Print["debug: ",#];#)&, #&]


(* ::Subsubsection:: *)
(*utilities*)


   (* RawJSON is not available V10 *)
   (* https://mathematica.stackexchange.com/a/55746/5478 *)
toAssociation = Replace[#,a:{__Rule}:>Association[a],{0,\[Infinity]}]&;

   (* robust url fetch with respect to encoding *)
   (* https://mathematica.stackexchange.com/q/154245/5478 *)
bytesToAssociation[bytes:{__Integer}]:= toAssociation @ ImportString[FromCharacterCode[bytes], "JSON"]
bytesToAssociation[___]=$Failed;


   (*URLFetch RawJSON utility*)

(*TODO: add content-encoding resolving for pre V11.*)

urlExecute[p_, r___]:= Module[{response}
, response = URLFetch[p, {"StatusCode", "ContentData"}, r]

; Switch[ 
      response
    , {200, {__Integer}}
    , bytesToAssociation @ Last @ response
    
    , {404, {__Integer}}
    , 404
    
    , {_Integer, {__Integer}}
    , Message[
        MPMInstall::fetchIssue
      , p
      , First @ response
      , FromCharacterCode @ Last @ response
      ]
    ; $Failed
    
    , _
    , Message[MPMInstall::fetchFailed, p]
    ; $Failed
  ]
];
 


(* ::Subsection:: *)
(*MPMInstall*)


(* ::Subsubsection::Closed:: *)
(*options*)


  (*not all options will be relevant for all repositories*)
  
  MPMInstall // Options = {
        "Method"              -> Automatic
      , "Logger"              -> Automatic
      , "Destination"         -> Automatic
      , "ConfirmRequirements" -> True
      (*, "AllowDrafts"         \[Rule] False (*whether to honor draft releases*)*)
      , "AllowPrereleases"    -> False (*whether to honor prereleases*)
      (*, "Credentials"         \[Rule] {} (*_String is considered a token, {_, _} is considered username/pw*)*)
      (*, "Version"             \[Rule] "latest"*)
  };


(* ::Subsubsection:: *)
(*messages*)


  MPMInstall::fetchIssue = "URL call to `` returned `` \n\n\t ``";
  MPMInstall::fetchFailed = "URL call to `` failed.";  
  
  MPMInstall::noass      = "There are no release .paclet files for ``/``";
  MPMInstall::invmth     = "Unknown method: ``";
  MPMInstall::insreq      = "Paclet `1`-`2` was installed but can't be foud. Please review requirements:\n`3`";
 
  
  MPMInstall::noResults   = "Failed to find any release matching those criteria.";
  MPMInstall::invRepo     = "Failed to find ``/`` respository, make sure author and project name are correct.";
  MPMInstall::invRelease  = "Release ``/``/`` does not exist.";
  MPMInstall::invReleaseSpec    = "Invalid release specification: ``.";


(* ::Subsubsection:: *)
(*strings*)


(*defined as messages but will be used with StringTemplate*)


  MPMInstall::assetsearch = "Searching for assets `1`/`2`/`3`";
  MPMInstall::dload       = "Downloading ``...";
  MPMInstall::inst        = "Installing ``...";


(* ::Subsubsection:: *)
(*Install method switch*)


  MPMInstall[
      args__
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[ { type = OptionValue["Method"] }

    , Switch[ type
        , Automatic | "gh-assets-paclet"
        , GitHubAssetInstall[args, patt]

        , _
        , Message[MPMInstall::invmth, type]; $Failed
      ]

  ];


(* ::Subsubsection::Closed:: *)
(*Install from url*)


    (*TODO: once PacletInstall supports https it will probably go*)
  MPMInstall[
      url_String /; StringMatchQ[url, "http"|"ftp"~~__~~".paclet"]
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[
      { temp
      , logger          = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      , pacletFileName  = FileNameTake @ url
      }

    , temp = FileNameJoin[{$TemporaryDirectory, CreateUUID[] <> ".paclet"}]

         (*TODO: check existence up front*)
    ;  Catch[
           logger @ StringTemplate[MPMInstall::dload] @ pacletFileName

         ; URLSave[url, temp]

         ; If[
               FileExistsQ @ temp
             , MPMInstall[ temp, patt, "PacletFileName" -> pacletFileName ]
             , Throw @ $Failed
           ]
       ]


  ];


(* ::Subsubsection::Closed:: *)
(*Install from file*)


    (*the final step*)
  MPMInstall[

      pacletPath_String ? FileExistsQ /; StringEndsQ[pacletPath, ".paclet"]
    , patt : OptionsPattern[{MPMInstall, PacletInstall, "PacletFileName" -> Automatic}]

  ]:= Module[

      { $logger     = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      , repo        = OptionValue["Destination"]
      , options     = FilterRules[{patt}, Options[PacletInstall]]
      , pacletName  = OptionValue["PacletFileName"] /. Automatic -> FileNameTake @ pacletPath
      , confirm     = OptionValue["ConfirmRequirements"]
      , paclet, found
      }

    , $logger @ StringTemplate[MPMInstall::inst] @ pacletName

    ; WithPacletRepository[repo] @ Catch[

          paclet = PacletInstall[pacletPath, options]
          
        ; Which[
              FailureQ @ paclet , Throw @ paclet
       (*     , $VersionNumber \[GreaterEqual] 11.2, Throw @ paclet  (*2*)*)
            , Not @ confirm, Throw @ paclet
          ]
          
          (*otherwise let's check if paclet is compatible manually*)
        ; found = PacletFind[paclet @ "Name"]

        ; If[
              Not @ MemberQ[found, paclet]
            , Message[MPMInstall::insreq, insReqArguments @ paclet]
          ]

        ; paclet



      ]

  ];

(*2 - since 11.2 PacletInstall will message about not compatible paclet.
   I did this test manually and there is MPMInstall::insreq message but then
   the build in one will be added. MPM's should stay because it is consistent
   with pre v11.2, natural choice is to surpress PacletInstall::compat to have
   uniform messages outcome too. I won't do that because someone may expect this 
   message and incorporating MPM to existing code will break it*)

(*1 - for custom destination we need to rebuild paclet data because otherwise 
  paclets from standard repositories may interfere and prompt samevers errors etc,
  moreover user can't use IgnoreVersion as he/she may not want to ignore version 
  with respect to custom destination
 *)

    insReqArguments[ paclet_ ]:= Sequence[
        paclet @ "Name"
      , paclet @  "Version"
      , paclet // requirementsString
    ];

    requirementsString = ExportString[
      List @@@ Normal @ KeyTake[
          {"Qualifier", "WolframVersion", "SystemID", "MathematicaVersion"}
      ] @ PacletInformation[#]
      ,
      "Table"
    ]&;




(* ::Subsection::Closed:: *)
(*Paclets Utilities*)


(* ::Subsubsection::Closed:: *)
(*WithPacletRepository*)


    (*Haven't found a trace of any option designed for this so we are using this helper function
      to install paclet in a desired directory.
      One should expect that the option IgnoreVersion -> True should be added too in order to
      ignore available paclets during installation/copying a specific paclet to e.g. dependencies
    *)

  WithPacletRepository::usage = "WithPacletRepository[dir][proc] creates environment for proc such that "<>
      "the PacletManager assumes dir to be user paclets' repository directory. "<>
      "The main purpose is to use with PacletInstall so that the paclet is installed "<>
      "e.g. in dependencies folder of another project.";

  WithPacletRepository[dir_String?DirectoryQ] := Function[
      expr
    , Module[{result}
      , Block[{ PacletManager`Package`$userRepositoryDir = dir}
        , RebuildPacletData[]
        ; result = expr
        ]
      ; RebuildPacletData[]  
      ; result
      ]
    , HoldFirst
  ];

  WithPacletRepository[Automatic] = Identity;





(* ::Subsubsection::Closed:: *)
(*PacletRepository*)


    (*In future we need to know whether desired paclets are in a specific directory regardless
      whether they are in others. PacletFind "Location" checks only for the paclet directory
      and can't understand paclet parent directory. It also checks with SameQ :( this wrapper should help

    So if you have e.g. MyPaclet installed in paclets/repository/folder you can confimr that with:

    PacletFind["MyPaclet", "Location" -> PacletRepository["paclets/repository/folder"]]

    otherwise one would have to use paclets/repository/folder/MyPalcet, which makes it pretty useless
    unless we want to confirm a specific paclet is exactly where we expect it*)

  PacletRepository::usage = "Symbolic wrapper for directory used as PacletFind's location.";
  PacletRepository // ClearAll;
  PacletRepository /: SameQ[pacletDir_, PacletRepository[dir_]] := StringMatchQ[
    pacletDir, dir ~~ __
  ];



(* ::Subsection:: *)
(*Specific installations*)


(* ::Subsubsection:: *)
(*GitHubAssetInstall*)


(* ::Subsubsubsection:: *)
(*GitHubAssetInstall*)


  GitHubAssetInstall::usage = "GitHubAssetInstall[author, pacletName] installs paclet distributed via GitHub repository release";

  GitHubAssetInstall // Options = Options @ MPMInstall;


  (*TODO: if version is not 'latest' check if it isn't already installed*)
  (*TODO: consider adding 'Force' option that will force overwriting instead of asking user*)
  (*TODO: add conditional progress indicator, based on $Notebooks and $logger wrapper*)



  GitHubAssetInstall[
      author_String
    , paclet_String
    , version_String:"latest"
    , patt : OptionsPattern[{GitHubAssetInstall, PacletInstall}]

  ]:=Module[
      { json, spec
      , downloads
      , pacletInstall
      , $logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      }

    , Catch[

          $logger @ StringTemplate[MPMInstall::assetsearch][  author, paclet, version ]

        ; spec = <|
            "paclet" -> paclet, "author" -> author, "version" -> version
          , Options @ GitHubAssetInstall
          , "logger" -> $logger
          , patt
          |>
          
        ; dPrint @ spec  
        
        ; downloads = If[ 
              TrueQ[ Or[
                Lookup[spec, "AllowPrereleases", False]
              (*, Lookup[spec, {"AllowDrafts", "AllowPrereleases"}, False]*)
              , Not @ StringQ @ spec @ "version"  
              ]]
            , assetsPacletsFind @ spec
            , assetsPacletsFindBasic @ spec
          ]

        ; Switch[
            downloads
          , {}  
          , Message[MPMInstall::noass, paclet, version]
          ; Throw @ $Failed
          
          , {_String}       
          , MPMInstall[First @ downloads, patt]
          
          , {__String}
          , MPMInstall[#, patt]& /@ downloads
          
          , _ (*TODO: something more verbose*)
          , $Failed

        ]
    ]
  ];




(* ::Subsubsubsection:: *)
(*fetch latest links*)


assetsPacletsFindBasic[spec_Association]:= Module[{json}
, dPrint["basic assets search"]
; Catch[
    json = urlExecute @ $SpecificReleaseUrlTemplate @ spec
  ; If[ 
      json === 404
    , Message[MPMInstall::invRelease, spec["author"], spec["paclet"], spec["version"]]
    ; Throw @ $Failed
    ] 
  ; releaseAssetPacletUrlCases @ json
  ]
];

assetsPacletsFindBasic[___]=$Failed;


(*currently this is used when allow prereleases is asked so no filter related to that will be create,
in future this will be only on of requirements for filtering/sorting so should be taken into account.

Not sure about final approach but it will be two step, createing filtering function based on options proviaded
and then creating sorting/extracting function based on options.

 Which when composed should return release association we can parse later *)

assetsPacletsFind[spec_Association]:=Module[{releases, picker, release}

 , dPrint["full assets search"]
 ; Catch[
        releases = urlExecute @ $ReleaseUrlTemplate @ spec
        
      ; If[ 
          releases === 404
        , Message[MPMInstall::invRepo, spec["author"], spec["paclet"]]
        ; Throw @ $Failed
        ]
          
      ; If[
          Not @ MatchQ[releases, {__Association}]
        , Message[MPMInstall::noass, spec@"author", spec @ "paclet"]
        ; Throw @ $Failed
        ]
        
        (*let's assume picker should always return list of one release*)
      ; picker = Switch[ spec["version"]  
        , "latest"
        , SortBy[-AbsoluteTime[#"created_at"]& ][[{1}]]
        
        , _String
        , Select[#"tag_name"===spec["version"]&]
        
        , _
        , Message[MPMInstall::invReleaseSpec, spec["version"]]
        ; Throw @{}
        ]
        
      ; release = picker @ releases  
      ; If[ 
          MatchQ[release,  {__Association}]
        , release = First @ release
        , Message[MPMInstall::noResults, spec["version"]]
        ; Throw @ $Failed
        ]
      ; releaseAssetPacletUrlCases @ release
    ]
];


assetsPacletsFind[___] = $Failed;


(* ::Subsubsubsection:: *)
(*misc*)


  $GitHubReleaseURL = "https://api.github.com/repos/`author`/`paclet`/releases";
  $ReleaseUrlTemplate = StringTemplate @ $GitHubReleaseURL;
  
  $SpecificReleaseUrlTemplate = StringTemplate @StringJoin[
    $GitHubReleaseURL, "/", "<* If[#version =!= \"latest\", \"tags/\", \"\"] *>`version`"
  ];


releaseAssetPacletUrlCases[release_Association]:=Check[
        Select[
          release[["assets", All, "browser_download_url"]]
        , StringMatchQ[#, __~~".paclet"]&
        ]
      , {}
     ];


(*      ; target = FileNameJoin[{CreateDirectory[], "paclet.paclet"}]
   ; If[
            $Notebooks
          , PrintTemporary @ Labeled[ProgressIndicator[Appearance -> "Necklace"]
              , "Downloading...", Right]
          , Print["Downloading..."]
        ]
      ; URLSave[download, target]
      , Return[$Failed]
    ]
  ; If[FileExistsQ[target], PacletInstall[target], $Failed]
]*)


(* ::Section:: *)
(*End*)


End[];

EndPackage[];
