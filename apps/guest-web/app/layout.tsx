import type { Metadata } from "next";
import "./styles.css";

export const metadata: Metadata = {
  title: "Before I Buy",
  description: "Um convite privado para uma perspectiva de compra.",
  robots: { index: false, follow: false },
  referrer: "no-referrer",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="pt-BR"><body>{children}</body></html>;
}
