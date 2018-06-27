FROM ubuntu AS build-env

ENV GOARCH=arm64
ENV GOOS=linux

RUN apt-get -yq update
RUN apt-get -yq install software-properties-common sudo
RUN apt-add-repository universe
RUN apt-add-repository multiverse
RUN apt-get -yq update
RUN apt-get -yq install gcc-aarch64-linux-gnu git make gcc bc device-tree-compiler u-boot-tools \
  ncurses-dev qemu-user-static wget cpio kmod squashfs-tools bison flex libssl-dev patch \
  xz-utils b43-fwcutter bzip2 ccache gawk golang
RUN apt-get -yq clean
RUN go get -d github.com/kubernetes-csi/external-attacher || true
RUN cd /root/go/src/github.com/kubernetes-csi/external-attacher && \
    git checkout refs/tags/v0.3.0 && \
    REV=$(git describe --long --match='v*' --dirty) && \
    mkdir -p bin && \
    CGO_ENABLED=0 go build -a -ldflags "-X main.version=$REV -extldflags '-static'" -o ./bin/csi-attacher ./cmd/csi-attacher

FROM arm64v8/alpine:3.7
LABEL description="CSI External Attacher"

COPY --from=build-env /root/go/src/github.com/kubernetes-csi/external-attacher/bin/csi-attacher csi-attacher
ENTRYPOINT ["/csi-attacher"]
