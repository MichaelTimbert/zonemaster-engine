with (import <nixpkgs> {});
let
   MIMEBase32 = pkgs.perl538Packages.buildPerlPackage {
    pname = "MIME-Base32";
    version = "1.303";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RE/REHSACK/MIME-Base32-1.303.tar.gz";
      hash = "sha256-qyH6mRMOM6Cv9s21lvZH5eVl0gfWNLou8Gvb71BCTpk=";
    };
    meta = {
      homepage = "https://metacpan.org/release/MIME-Base32";
      description = "Base32 encoder and decoder";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

#Locale::TextDomain 
libintlperl = pkgs.perl538Packages.buildPerlPackage {
    pname = "libintl-perl";
    version = "1.33";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GU/GUIDO/libintl-perl-1.33.tar.gz";
      hash = "sha256-USbtqczQ7rENuC3e9jy8r329dx54zA+xEMw7WmuGeec=";
    };
    meta = {
      homepage = "http://www.guido-flohr.net/en/projects/";
      description = "High-Level Interface to Uniforum Message Translation";
    };
  };

#YAML::XS
YAMLLibYAML = pkgs.perl538Packages.buildPerlPackage {
    pname = "YAML-LibYAML";
    version = "0.902.0";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TI/TINITA/YAML-LibYAML-v0.902.0.tar.gz";
      hash = "sha256-r96ErAqXumMdSrx+BWKRCDlWS5Pu+JxBdC9X0ongNEA=";
    };
    meta = {
      homepage = "https://github.com/ingydotnet/yaml-libyaml-pm";
      description = "Perl YAML Serialization using XS and libyaml";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
# Mail::SPF
  MailSPF = pkgs.perl538Packages.buildPerlPackage {
    pname = "Mail-SPF";
    version = "3.20240923";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MB/MBRADSHAW/Mail-SPF-3.20240923.tar.gz";
      hash = "sha256-3TSMqvSUfsUBP3nMZq6ZuSs4uHI2Ge++NnYOEssiFDA=";
    };
    buildInputs = with perl538Packages; [ NetDNSResolverProgrammable ];
    propagatedBuildInputs = with perl538Packages; [ Error NetAddrIP NetDNS URI ];
    meta = {
      description = "An object-oriented implementation of Sender Policy Framework";
      license = lib.licenses.bsd3;
    };
  };
ZonemasterLDNS = pkgs.perl538Packages.buildPerlPackage {
    pname = "Zonemaster-LDNS";
    version = "3.2.0";
    src = ../zonemaster-ldns;
    env.NIX_CFLAGS_COMPILE = "-I${pkgs.openssl.dev}/include -I${pkgs.libidn2}.dev}/include";
    NIX_CFLAGS_LINK = "-L${lib.getLib pkgs.openssl}/lib -L${lib.getLib pkgs.libidn2}/lib -lcrypto -lidn2";

    makeMakerFlags = [ "--prefix-openssl=${pkgs.openssl.dev}" ];

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs.perl538Packages; [ DevelChecklib ModuleInstall ModuleInstallXSUtil TestFatal TestDifferences pkgs.ldns pkgs.libidn2 pkgs.openssl MIMEBase32];
    meta = {
      description = "Perl wrapper for the ldns DNS library";
      license = with lib.licenses; [ bsd3 ];
    };
  };

in
mkShell {
  
    #NIX_CFLAGS_COMPILE = "-I${pkgs.openssl.dev}/include -I${pkgs.libidn2}.dev}/include";
    #NIX_CFLAGS_LINK = "-L${lib.getLib pkgs.openssl}/lib -L${lib.getLib pkgs.libidn2}/lib -lcrypto -lidn2";

    #makeMakerFlags = [ "--prefix-openssl=${pkgs.openssl.dev}" ];
	# perl Makefile.PL --prefix-openssl=/nix/store/i4zk1906f863gjp39vhsjl1imkwyp4qs-openssl-3.3.2-dev
buildInputs = with perl538Packages; [
	ZonemasterLDNS
	# for perl Makefile.PL
	perl538
	perl538Packages.ModuleInstall
	# for test
	FileShareDir
	libintlperl # for Locale::TextDomain
	perl538Packages.ClassAccessor
	perl538Packages.NetDNS
	perl538Packages.NetIPXS
	perl538Packages.TextCSV
	perl538Packages.Readonly
	perl538Packages.FileSlurp
	perl538Packages.Clone
	perl538Packages.LogAny
	YAMLLibYAML # for YAML::XS
	perl538Packages.ListMoreUtils
	ModuleFind
 	IOSocketINET6
	EmailValid
	MailSPF # for Mail::SPF
	TryTiny
	TestFatal
	TestNoWarnings
	TestDifferences 
	SubOverride
	LocalePO 
	TestException
	gettext# pakage utils pour t/po-files
	git# pour t/po-files
	PodCoverage # t/pod-coverage.t
	TestPod # t/pod.t
		];
}
