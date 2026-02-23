#!/bin/bash

# AI SDR Agency - 每日工作流程脚本
# Usage: ./daily-workflow.sh

set -e

WORKSPACE="/root/.openclaw/workspace/sdr-agency"
DATE=$(date +%Y-%m-%d)
LOG_FILE="$WORKSPACE/logs/daily-$DATE.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

# 创建日志目录
mkdir -p "$WORKSPACE/logs"

echo "========================================"
echo "  AI SDR Agency - 每日工作流"
echo "  日期: $DATE"
echo "========================================"
echo ""

# ========================================
# 步骤 1: 检查邮件回复
# ========================================
log "📧 步骤 1: 检查邮件回复..."

# 读取 ClawMail 配置
if [ -f "$HOME/.clawmail/config.json" ]; then
    SYSTEM_ID=$(cat "$HOME/.clawmail/config.json" | grep -o '"system_id": "[^"]*"' | cut -d'"' -f4)
    INBOX_ID=$(cat "$HOME/.clawmail/config.json" | grep -o '"inbox_id": "[^"]*"' | cut -d'"' -f4)
    
    # 检查新邮件
    RESPONSE=$(curl -s -H "X-System-ID: $SYSTEM_ID" \
        "https://api.clawmail.cc/v1/inboxes/$INBOX_ID/poll")
    
    HAS_NEW=$(echo "$RESPONSE" | grep -o '"has_new":[^,}]*' | cut -d':' -f2)
    
    if [ "$HAS_NEW" = "true" ]; then
        NEW_COUNT=$(echo "$RESPONSE" | grep -o '"emails":\[' | wc -l)
        log "✅ 发现新邮件! 需要人工处理"
        echo "$RESPONSE" | grep -o '"subject":"[^"]*"' | head -5
    else
        log "📭 暂无新回复"
    fi
else
    warn "ClawMail 配置未找到"
fi

echo ""

# ========================================
# 步骤 2: 准备今日工作清单
# ========================================
log "📝 步骤 2: 生成今日工作清单..."

TODO_FILE="$WORKSPACE/daily-tasks/$DATE.md"
mkdir -p "$WORKSPACE/daily-tasks"

cat > "$TODO_FILE" << EOF
# $DATE 工作任务

## 上午 (9:00-12:00)
- [ ] 检查并回复邮件 (已完成自动检查)
- [ ] 搜索 20 个新潜在客户
- [ ] 研究并个性化 10 封邮件

## 下午 (13:00-17:00)
- [ ] 发送 10 封冷邮件
- [ ] 跟进之前线索
- [ ] 更新 CRM/跟踪表

## 今日目标
- 新线索: 20
- 邮件发送: 10
- 预期回复: 2+

## 备注
$(date)
EOF

log "✅ 工作清单已保存: $TODO_FILE"

# ========================================
# 步骤 3: 数据报告
# ========================================
log "📊 步骤 3: 生成数据快照..."

# 计算本周数据
WEEK_START=$(date -d "$(date +%u) days ago" +%Y-%m-%d 2>/dev/null || echo "$DATE")

REPORT_FILE="$WORKSPACE/reports/daily-$DATE.md"
mkdir -p "$WORKSPACE/reports"

cat > "$REPORT_FILE" << EOF
# $DATE 数据报告

## 本周概览
- 报告周期: $WEEK_START 至 $DATE
- 生成时间: $(date '+%H:%M:%S')

## 关键指标
| 指标 | 本周 | 目标 | 状态 |
|------|------|------|------|
| 新线索 | [待填写] | 100 | - |
| 邮件发送 | [待填写] | 50 | - |
| 收到回复 | [待填写] | 10 | - |
| 预约会议 | [待填写] | 5 | - |

## 下一步行动
1. [ ] 继续搜索新线索
2. [ ] 跟进高意向回复
3. [ ] 优化邮件模板

## 备注
- 落地页: https://horaszhang.github.io/ai-sdr-agency
- 邮箱: horace-sdr-agency@clawmail.cc
EOF

log "✅ 报告已保存: $REPORT_FILE"

# ========================================
# 步骤 4: 检查基础设施
# ========================================
log "🔧 步骤 4: 检查基础设施状态..."

# 检查落地页
LANDING_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://horaszhang.github.io/ai-sdr-agency/)
if [ "$LANDING_STATUS" = "200" ]; then
    log "✅ 落地页正常: https://horaszhang.github.io/ai-sdr-agency/"
else
    warn "落地页状态异常: HTTP $LANDING_STATUS"
fi

# 检查邮箱
echo ""
log "📧 邮箱配置:"
log "  地址: horace-sdr-agency@clawmail.cc"
log "  系统: ClawMail"

echo ""

# ========================================
# 完成
# ========================================
echo "========================================"
log "🎉 每日工作流初始化完成!"
echo "========================================"
echo ""
echo "今日任务清单: $TODO_FILE"
echo "数据报告: $REPORT_FILE"
echo ""
echo "下一步:"
echo "1. 查看任务清单并开始工作"
echo "2. 搜索潜在客户 (使用 Apollo)"
echo "3. 发送个性化冷邮件"
echo ""
