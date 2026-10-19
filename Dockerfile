ARG DOCKER_HUB="docker.io"
ARG NGINX_VERSION="1.17.6"
ARG NODE_VERSION="24-alpine"

FROM $DOCKER_HUB/library/node:$NODE_VERSION AS build

WORKDIR /workspace

ARG NPM_REGISTRY="https://registry.npmjs.org"

# Copia primeiro os manifestos de dependências para que alterações no código não invalidem a camada de instalação.
COPY package.json package-lock.json ./

# Mantém os pacotes baixados do npm em um cache do BuildKit reutilizável entre builds.
RUN --mount=type=cache,target=/root/.npm \
    printf 'registry=%s\n' "$NPM_REGISTRY" > .npmrc && \
    npm ci --cache /root/.npm

# Copia os arquivos da aplicação após instalar as dependências para preservar essa camada de cache.
COPY . .

# Publica a aplicação Angular em /petclinic/, conforme a localização configurada no Nginx.
RUN npm run build -- --configuration production --base-href /petclinic/

FROM $DOCKER_HUB/library/nginx:$NGINX_VERSION AS runtime

# Copia os arquivos gerados para o subcaminho definido no base href da aplicação.
COPY --from=build /workspace/dist/browser/ /usr/share/nginx/html/petclinic/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
# Gera a configuração da API em runtime a partir de REST_API_URL quando o container iniciar.
COPY docker/runtime-config.js.template /etc/petclinic/runtime-config.js.template
COPY docker/runtime-entrypoint.sh /usr/local/bin/runtime-entrypoint.sh

# Permite que o Nginx grave arquivos em runtime, normaliza as quebras de linha e executa sem privilégios de root.
RUN chmod a+rwx /var/cache/nginx /var/run /var/log/nginx && \
    sed -i 's/\r$//' /usr/local/bin/runtime-entrypoint.sh && \
    chmod +x /usr/local/bin/runtime-entrypoint.sh && \
    sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf

EXPOSE 8080

USER nginx

HEALTHCHECK CMD ["nginx", "-t"]

# Gera a configuração em runtime antes de iniciar o Nginx.
ENTRYPOINT ["/usr/local/bin/runtime-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
