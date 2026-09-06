import { globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";

const config = [
  globalIgnores([".next/**", ".open-next/**", "coverage/**", "playwright-report/**", "next-env.d.ts"]),
  ...nextVitals,
  ...nextTypeScript,
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      "no-console": "error"
    }
  }
];

export default config;
