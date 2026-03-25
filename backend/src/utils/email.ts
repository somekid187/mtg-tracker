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

type SendMatchInviteEmailParams = {
  to: string;
  inviterUsername: string;
  matchName: string;
  inviteCode: string;
  joinUrl: string;
};

export async function sendMatchInviteEmail(params: SendMatchInviteEmailParams) {
  const { host, port, user, pass, from, secure } = getSmtpConfig();
  const appName = process.env.APP_NAME || "mtg-tracker";

  const transporter = nodemailer.createTransport({ host, port, secure, auth: { user, pass } });

  const html = `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/></head>
<body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background:#f6f7fb;padding:24px 12px;">
    <tr><td align="center">
      <table role="presentation" cellpadding="0" cellspacing="0" width="600" style="max-width:600px;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 8px 30px rgba(17,24,39,0.08);">
        <tr><td style="padding:22px 24px;background:#111827;color:#fff;"><div style="font-size:16px;font-weight:700;">${appName}</div></td></tr>
        <tr><td style="padding:26px 24px 8px 24px;"><div style="font-size:20px;font-weight:700;">You've been invited to a match!</div></td></tr>
        <tr><td style="padding:0 24px 16px 24px;"><div style="font-size:14px;line-height:1.55;color:#374151;">
          <strong>${params.inviterUsername}</strong> has invited you to join <strong>${params.matchName || "a match"}</strong> on ${appName}.
        </div></td></tr>
        <tr><td style="padding:0 24px 18px 24px;">
          <div style="background:#f3f4f6;border:1px solid #e5e7eb;border-radius:12px;padding:14px 16px;">
            <div style="font-size:12px;color:#6b7280;margin-bottom:6px;">Your invite code</div>
            <div style="font-size:22px;font-weight:700;letter-spacing:3px;color:#111827;">${params.inviteCode}</div>
          </div>
        </td></tr>
        <tr><td style="padding:0 24px 22px 24px;">
          <a href="${params.joinUrl}" style="display:inline-block;background:#2563eb;color:#fff;text-decoration:none;padding:12px 20px;border-radius:10px;font-weight:700;font-size:14px;">Join Match</a>
          <div style="font-size:12px;color:#6b7280;margin-top:10px;">Or paste this link: <span style="color:#374151;word-break:break-all;">${params.joinUrl}</span></div>
        </td></tr>
        <tr><td style="padding:0 24px 26px 24px;"><div style="font-size:12px;color:#6b7280;">If you weren't expecting this invite, you can ignore this email.</div></td></tr>
      </table>
      <div style="max-width:600px;font-size:11px;color:#9ca3af;padding:10px 8px;">© ${new Date().getFullYear()} ${appName}</div>
    </td></tr>
  </table>
</body>
</html>`;

  await transporter.sendMail({
    from,
    to: params.to,
    subject: `${params.inviterUsername} invited you to a match on ${appName}`,
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

