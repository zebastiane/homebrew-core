class Stunnel < Formula
  desc "SSL tunneling program"
  homepage "https://www.stunnel.org/"
  url "https://www.stunnel.org/downloads/stunnel-5.44.tar.gz"
  mirror "https://www.usenix.org.uk/mirrors/stunnel/stunnel-5.44.tar.gz"
  sha256 "990a325dbb47d77d88772dd02fbbd27d91b1fea3ece76c9ff4461eca93f12299"

  bottle do
    sha256 "3999aeebd42c9be5a6264746dfa009709d164929d20d26f86cfff30740c4639d" => :high_sierra
    sha256 "619f3838b8e165fc019854242d8c60f5d4d72369d70be1d78cecc46042a2c0b9" => :sierra
    sha256 "20be9c5027e7d0990079543d0288d51962fdb1d1812f0bdbce22884969eb45ef" => :el_capitan
  end

  depends_on "openssl"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}",
                          "--localstatedir=#{var}",
                          "--mandir=#{man}",
                          "--disable-libwrap",
                          "--disable-systemd",
                          "--with-ssl=#{Formula["openssl"].opt_prefix}"
    system "make", "install"

    # This programmatically recreates pem creation used in the tools Makefile
    # which would usually require interactivity to resolve.
    cd "tools" do
      args = %w[req -new -x509 -days 365 -rand stunnel.rnd -config
                openssl.cnf -out stunnel.pem -keyout stunnel.pem -sha256 -subj
                /C=PL/ST=Mazovia\ Province/L=Warsaw/O=Stunnel\ Developers/OU=Provisional\ CA/CN=localhost/]
      system "dd", "if=/dev/urandom", "of=stunnel.rnd", "bs=256", "count=1"
      system "#{Formula["openssl"].opt_bin}/openssl", *args
      chmod 0600, "stunnel.pem"
      (etc/"stunnel").install "stunnel.pem"
    end
  end

  def caveats
    <<~EOS
      A bogus SSL server certificate has been installed to:
        #{etc}/stunnel/stunnel.pem

      This certificate will be used by default unless a config file says otherwise!
      Stunnel will refuse to load the sample configuration file if left unedited.

      In your stunnel configuration, specify a SSL certificate with
      the "cert =" option for each service.
    EOS
  end

  test do
    (testpath/"tstunnel.conf").write <<~EOS
      cert = #{etc}/stunnel/stunnel.pem

      setuid = nobody
      setgid = nobody

      [pop3s]
      accept  = 995
      connect = 110

      [imaps]
      accept  = 993
      connect = 143
    EOS

    assert_match "successful", pipe_output("#{bin}/stunnel #{testpath}/tstunnel.conf 2>&1")
  end
end
