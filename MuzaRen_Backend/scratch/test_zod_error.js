const { z } = require('zod');
const schema = z.object({ email: z.string().email() });
try {
  schema.parse({ email: 'invalid' });
} catch (e) {
  console.log(e.name);
  console.log(e.errors);
  console.log(e.issues);
}
