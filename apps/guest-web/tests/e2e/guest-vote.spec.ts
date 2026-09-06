import { expect, test } from "@playwright/test";

const token = "A".repeat(43);

test("guest votes through the same-origin proxy and only then sees aggregates", async ({ page }) => {
  await page.goto(`/invite/${token}`);
  await expect(page.getByRole("heading", { name: "Lu quer sua perspectiva" })).toBeVisible();
  await expect(page.getByText("Perspectivas do grupo")).toHaveCount(0);
  await page.getByLabel(/Esperar/).check();
  await page.getByRole("button", { name: "Enviar meu palpite" }).click();
  await expect(page.getByRole("heading", { name: "Seu palpite entrou" })).toBeVisible();
  await page.getByRole("button", { name: "Ver como o grupo respondeu" }).click();
  await expect(page.getByRole("heading", { name: "Perspectivas do grupo" })).toBeVisible();
  await expect(page.getByLabel(/3 palpites no total/)).toBeVisible();
  await page.getByRole("button", { name: "Mudar meu palpite" }).click();
  await page.getByLabel(/Comprar/).check();
  await page.getByRole("button", { name: "Enviar meu palpite" }).click();
  await expect(page.getByText("Você escolheu", { exact: false })).toContainText("Comprar");
});

test("revoked or unavailable invite remains generic", async ({ page }) => {
  await page.goto(`/invite/${"R".repeat(43)}`);
  await expect(page.getByRole("heading", { name: "Este convite não está disponível" })).toBeVisible();
  await expect(page.getByText("Fone com cancelamento")).toHaveCount(0);
});

test("critical vote remains keyboard-accessible at 320px and 200% text", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 800 });
  await page.goto(`/invite/${token}`);
  await page.locator("html").evaluate((element) => {
    element.style.fontSize = "200%";
  });
  for (let step = 0; step < 10; step += 1) {
    await page.keyboard.press("Tab");
    if (await page.locator('main input[type="radio"]:focus').count()) break;
  }
  const focused = page.locator('main input[type="radio"]:focus');
  await expect(focused).toHaveCount(1);
  await page.keyboard.press("Space");
  const submit = page.getByRole("button", { name: "Enviar meu palpite" });
  for (let step = 0; step < 5; step += 1) {
    await page.keyboard.press("Tab");
    if (await submit.evaluate((element) => element === document.activeElement)) break;
  }
  await expect(submit).toBeFocused();
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
  );
  expect(overflow).toBe(false);
  await page.keyboard.press("Enter");
  await expect(page.getByRole("heading", { name: "Seu palpite entrou" })).toBeVisible();
});
