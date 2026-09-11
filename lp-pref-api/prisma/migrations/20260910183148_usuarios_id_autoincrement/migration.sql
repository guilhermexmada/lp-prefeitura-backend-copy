-- AlterTable
CREATE SEQUENCE usuarios_id_seq;
ALTER TABLE "usuarios" ALTER COLUMN "id" SET DEFAULT nextval('usuarios_id_seq');
ALTER SEQUENCE usuarios_id_seq OWNED BY "usuarios"."id";

SELECT setval(
  'usuarios_id_seq',
  COALESCE((SELECT MAX(id) FROM usuarios), 1)
);