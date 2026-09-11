import { prisma } from './src/lib/prisma.js';

async function main() {
  const departamentos = await prisma.departamentos.findMany({
    where: { ativo: true },
  });
  console.log(departamentos);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });