using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CameraColorTextureFeature : ScriptableRendererFeature
{
    private string m_ProfilerTag;
    class CameraColorTexturePass : ScriptableRenderPass
    {
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }
        private RenderTargetHandle m_TemporaryColorTexture;
        private string m_ProfilerTag;
        public CameraColorTexturePass(RenderPassEvent passEvent)
        {
            renderPassEvent = passEvent;
            m_ProfilerTag = "Get Camera Color Texture";
            m_TemporaryColorTexture.Init("_CameraColorTextureAlpha");
        }

        public void Setup(RenderTargetIdentifier sourceId)
        {
            source = sourceId;
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer buffer = CommandBufferPool.Get(m_ProfilerTag);
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            // opaqueDesc.depthBufferBits = 0;
            buffer.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc, FilterMode.Bilinear);
            Blit(buffer, source, m_TemporaryColorTexture.Identifier());
            buffer.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
            context.ExecuteCommandBuffer(buffer);
            CommandBufferPool.Release(buffer);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {

        }
    }

    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;

    CameraColorTexturePass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CameraColorTexturePass(renderPassEvent);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


