FROM registry.smtx.io/library/golang:1.24 AS builder
ENV GO111MODULE=on
ARG BUILD_VERSION
RUN go env -w GOPROXY="https://goproxy.cn|direct" GONOSUMDB=""
WORKDIR /build
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY pkg/ pkg/
COPY version/ version/
RUN CGO_ENABLED=0 go build -ldflags="-extldflags=-static -X github.com/IBM/staticroute-operator/version.Version=${BUILD_VERSION}"  -o /staticroute-operator main.go

# Intermediate stage to apply capabilities
FROM registry.smtx.io/kubesmart/runtime:alpine-3 AS intermediate
COPY --from=builder /staticroute-operator /staticroute-operator
RUN setcap cap_net_admin+ep /staticroute-operator
RUN chmod go+x /staticroute-operator

FROM registry.smtx.io/kubesmart/runtime:alpine-3
COPY --from=intermediate /staticroute-operator /staticroute-operator
USER 2000:2000
ENTRYPOINT ["/staticroute-operator"]
