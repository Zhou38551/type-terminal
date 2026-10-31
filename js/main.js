// 全局变量
let currentTargetText = "";
let startTime = null;
let timerInterval = null;
let isFinished = false;
let isComposing = false; // 核心：检测是否正在输入拼音

// 页面加载完毕后，渲染首页文章列表
window.onload = function() {
    const list = document.getElementById('text-list');
    let html = "";
    for (let key in TEXTS) {
        // 动态生成按钮，点击时调用 startTyping 并传入文章名
        html += `<button onclick="startTyping('${key}')">Load: ${key}</button>`;
    }
    list.innerHTML = html;
}

// 切换页面并开始打字
function startTyping(key) {
    currentTargetText = TEXTS[key];
    
    // 切换 UI
    document.getElementById('home-screen').classList.remove('active');
    document.getElementById('typing-screen').classList.add('active');
    
    initTextDisplay();
    resetStats();
    
    // 自动聚焦到输入框
    const inputBox = document.getElementById('input-box');
    inputBox.value = "";
    inputBox.disabled = false;
    inputBox.focus();
}

// 返回主页
function goHome() {
    document.getElementById('typing-screen').classList.remove('active');
    document.getElementById('home-screen').classList.add('active');
    if (timerInterval) clearInterval(timerInterval);
    startTime = null;
    isFinished = false;
}

// 初始化要打的文字 (把每个字拆成 span)
function initTextDisplay() {
    const display = document.getElementById('text-display');
    display.innerHTML = '';
    for (let char of currentTargetText) {
        const span = document.createElement('span');
        span.innerText = char;
        display.appendChild(span);
    }
    // 给第一个字加光标高亮
    if (display.children.length > 0) {
        display.children[0].classList.add('current');
    }
}

// 重置数据面板
function resetStats() {
    document.getElementById('time').innerText = "0.0";
    document.getElementById('wpm').innerText = "0";
    document.getElementById('error-rate').innerText = "100";
}

// ====== 核心输入逻辑 ======
const inputBox = document.getElementById('input-box');

// 1. 防误判机制：监听输入法的拼写事件
inputBox.addEventListener('compositionstart', () => { isComposing = true; });
inputBox.addEventListener('compositionend', () => { 
    isComposing = false; 
    handleInput(); // 拼音选字结束后，强制触发一次计算
});

// 2. 正常输入监听
inputBox.addEventListener('input', () => {
    if (isComposing) return; // 如果在打拼音，直接拦截，不算错误！
    handleInput();
});

function handleInput() {
    if (isFinished || isComposing) return;

    const inputText = inputBox.value;
    const spans = document.getElementById('text-display').querySelectorAll('span');
    
    // 防止输入超出原文长度
    if (inputText.length > currentTargetText.length) {
        inputBox.value = inputText.substring(0, currentTargetText.length);
        return;
    }

    // 第一次真正输入文字时，启动计时器
    if (!startTime && inputText.length > 0) {
        startTime = new Date();
        timerInterval = setInterval(updateTime, 100);
    }

    let errors = 0;

    // 逐字比对
    for (let i = 0; i < spans.length; i++) {
        spans[i].className = ''; // 清空之前的颜色
        
        if (i < inputText.length) {
            // 已经打过的字
            if (inputText[i] === currentTargetText[i]) {
                spans[i].classList.add('correct');
            } else {
                spans[i].classList.add('wrong');
                errors++;
            }
        } else if (i === inputText.length) {
            // 当前光标位置
            spans[i].classList.add('current');
        }
    }

    // 实时计算数据
    const timeElapsed = (new Date() - startTime) / 1000;
    const totalTyped = inputText.length;

    if (totalTyped > 0 && timeElapsed > 0) {
        // 速度 (WPM)
        const wpm = Math.round((totalTyped / timeElapsed) * 60);
        document.getElementById('wpm').innerText = wpm;
        
        // 准确率 (Acc)
        const accuracy = (((totalTyped - errors) / totalTyped) * 100).toFixed(1);
        document.getElementById('error-rate').innerText = accuracy;
    }

    // 检查是否打完
    if (inputText.length === currentTargetText.length) {
        isFinished = true;
        clearInterval(timerInterval);
        inputBox.disabled = true;
        inputBox.placeholder = "Test Completed!";
        // 移除最后的光标
        if (spans.length > 0) spans[spans.length-1].classList.remove('current');
    }
}

// 计时器刷新
function updateTime() {
    if (startTime) {
        const timeElapsed = ((new Date() - startTime) / 1000).toFixed(1);
        document.getElementById('time').innerText = timeElapsed;
    }
}