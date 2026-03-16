import nodemailer from "nodemailer";
import { readFile } from "node:fs/promises";
import path from "node:path";
import Handlebars from "handlebars";

type SendActivationEmailParams = {
  to: string;
  username: string;
  activationToken: string;
};

type SendPasswordResetEmailParams = {
  to: string;
  username: string;
  resetToken: string;
};

function getRequiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

function getSmtpConfig() {
  const host = process.env.SMTP_HOST || getRequiredEnv("EMAIL_HOST");
  const port = Number(process.env.SMTP_PORT || process.env.EMAIL_PORT || 587);
  const user = process.env.SMTP_USER || getRequiredEnv("EMAIL_USER");
  const pass = process.env.SMTP_PASS || getRequiredEnv("EMAIL_PASSWORD");
  const from = process.env.MAIL_FROM || process.env.EMAIL_FROM || user;
  const secure = port === 465;

  return { host, port, user, pass, from, secure };
}

function buildFrontendUrl(pathname: string, token: string) {
  const frontendUrl = process.env.FRONTEND_URL;
  if (!frontendUrl) return undefined;
  return `${frontendUrl.replace(/\/$/, "")}${pathname}?token=${encodeURIComponent(
    token,
  )}`;
}

export async function sendActivationEmail(params: SendActivationEmailParams) {
  const { host, port, user, pass, from, secure } = getSmtpConfig();
  const appName = process.env.APP_NAME || "mtg-tracker";
  const activationUrl = buildFrontendUrl("/activate", params.activationToken);

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });

  const html = await renderEmailTemplate({
    appName,
    name: params.username,
    code: params.activationToken,
    activationUrl,
  });

  await transporter.sendMail({
    from,
    to: params.to,
    subject: `${appName}: Activate your account`,
    html,
  });
}

export async function sendPasswordResetEmail(
  params: SendPasswordResetEmailParams,
) {
  const { host, port, user, pass, from, secure } = getSmtpConfig();
  const appName = process.env.APP_NAME || "mtg-tracker";
  const resetUrl = buildFrontendUrl("/reset-password", params.resetToken);

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });

  const html = await renderEmailTemplate({
    appName,
    name: params.username,
    code: params.resetToken,
    resetUrl,
  });

  await transporter.sendMail({
    from,
    to: params.to,
    subject: `${appName}: Reset your password`,
    html,
  });
}

async function renderEmailTemplate(args: {
  appName: string;
  name: string;
  code: string;
  activationUrl?: string;
  resetUrl?: string;
}) {
  const templatePath = path.join(
    process.cwd(),
    "src",
    "emails",
    "activation.hbs",
  );

  const source = await readFile(templatePath, "utf8");
  const template = Handlebars.compile(source);

  return template({
    appName: args.appName,
    name: args.name,
    code: args.code,
    activationUrl: args.activationUrl,
    resetUrl: args.resetUrl,
    year: new Date().getFullYear(),
  });
}

