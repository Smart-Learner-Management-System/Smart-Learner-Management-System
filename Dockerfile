FROM postgres:15-alpine
ENV POSTGRES_DB=smart_learner_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
COPY *.sql /docker-entrypoint-initdb.d/01-schema.sql
EXPOSE 5432
