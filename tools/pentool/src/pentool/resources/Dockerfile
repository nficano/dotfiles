FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive \
    GO111MODULE=on \
    VIRTUAL_ENV=/opt/pen-venv \
    PATH=/opt/pen-venv/bin:$PATH

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      jq \
      python3 \
      python3-pip \
      python3-venv \
      nmap \
      masscan \
      sslyze \
      nikto \
      sqlmap \
      amass \
      libpostal-data \
      gobuster \
      seclists \
      dnsutils \
      netcat-openbsd \
      make \
      wget \
      unzip \
      xz-utils \
      build-essential \
      libpcap-dev \
      golang \
      zaproxy \
      xsltproc && \
    libpostal_data download all /var/lib/libpostal && \
    rm -rf /usr/share/libpostal && \
    ln -s /var/lib/libpostal /usr/share/libpostal && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv "$VIRTUAL_ENV" && \
    "$VIRTUAL_ENV/bin/pip" install --no-cache-dir --upgrade pip && \
    "$VIRTUAL_ENV/bin/pip" install --no-cache-dir sslyze waybackpy

RUN go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest && \
    go install github.com/tomnomnom/waybackurls@latest && \
    cp /root/go/bin/* /usr/local/bin/ && \
    rm -rf /root/go

RUN mkdir -p /workspace
WORKDIR /workspace

CMD ["/bin/bash"]
