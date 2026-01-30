FROM directus/directus:11.14.0

ENV PORT=8055
EXPOSE 8055

USER root
RUN corepack enable
RUN npm i -g @directus/extensions-sdk

COPY ./extensions /directus/extensions


# Copy extensions source into the image
# COPY ./schema /directus/schema

# Copy entrypoint last
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER node

ENTRYPOINT ["/docker-entrypoint.sh"]